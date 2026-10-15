import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/data/reading_quota_controller.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/loading_page.dart';
import 'package:decision_compass/pages/result_page.dart';
import 'package:decision_compass/reading_dependencies.dart';
import 'package:decision_compass/services/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reading_test_rig.dart';

class TestAdService implements AdService {
  int initializeCalls = 0;
  int preloadCalls = 0;
  int showCalls = 0;
  bool loaded = false;

  @override
  bool get isInterstitialLoaded => loaded;

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  void preloadInterstitial() {
    preloadCalls++;
  }

  @override
  Future<void> showInterstitial({required VoidCallback onDismissed}) async {
    showCalls++;
    onDismissed();
  }
}

final _profile = AppProfile(
  userName: 'Alex',
  birthDate: DateTime(2001, 2, 12),
  birthCountryCode: 'VN',
  zodiacSign: ZodiacSign.aquarius,
  useCurrentLocation: false,
  safetyAcknowledged: true,
);

ReadingDependencies _depsWithAd(
  ReadingTestRig rig,
  ReadingQuotaController quota,
  AdService adService,
) {
  final d = rig.dependencies;
  return ReadingDependencies(
    repository: d.repository,
    contextProvider: d.contextProvider,
    historyRepository: d.historyRepository,
    profileRepository: d.profileRepository,
    dailyBriefProvider: d.dailyBriefProvider,
    homeDescriptionDeck: d.homeDescriptionDeck,
    dailyEnergyInsights: d.dailyEnergyInsights,
    localeController: d.localeController,
    quotaManager: quota,
    adService: adService,
    nowUtc: d.nowUtc,
    nowLocal: d.nowLocal,
  );
}

Widget _loadingWidget({
  required ReadingTestRig rig,
  required ReadingQuotaController quota,
  required AdService adService,
}) => localizedApp(
  home: LoadingPage(
    mode: DecisionMode.yesNo,
    period: TimePeriod.now,
    category: engine.ReadingCategory.general,
    profile: _profile,
    instantUtc: rig.revealInstant,
    dependencies: _depsWithAd(rig, quota, adService),
  ),
);

Future<void> _finishRitual(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 5400));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    '1st reading of the day: clean experience, NO interstitial ad shown',
    (tester) async {
      final quota = SharedPreferencesReadingQuotaController();
      final adService = TestAdService();
      final rig = ReadingTestRig(response: fixtureResponse('ready_yes_no_now.json'));

      await tester.pumpWidget(
        _loadingWidget(rig: rig, quota: quota, adService: adService),
      );
      await _finishRitual(tester);

      // Loading completed, result is visible
      expect(find.byType(ResultPage), findsOneWidget);
      // Preload was called during initState
      expect(adService.preloadCalls, 1);
      // But show was NOT called because it is the 1st reading
      expect(adService.showCalls, 0);
      expect(quota.dailyCompletedReadingsCount(rig.localClock), 1);
    },
  );

  testWidgets(
    '2nd reading of the day onwards: Interstitial ad IS triggered',
    (tester) async {
      final quota = SharedPreferencesReadingQuotaController();
      final now = DateTime(2026, 10, 9, 9);
      // First reading already done earlier today
      await quota.consumeReading(now);
      expect(quota.dailyCompletedReadingsCount(now), 1);

      // Give bonus so user can take a 2nd reading
      await quota.earnBonusReading();

      final adService = TestAdService();
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        localNow: now.add(const Duration(minutes: 10)),
      );

      await tester.pumpWidget(
        _loadingWidget(rig: rig, quota: quota, adService: adService),
      );
      await _finishRitual(tester);

      // Result is displayed
      expect(find.byType(ResultPage), findsOneWidget);
      // Preload was called
      expect(adService.preloadCalls, 1);
      // Show was triggered because completed count was >= 1 prior to this reading
      expect(adService.showCalls, 1);
      expect(quota.dailyCompletedReadingsCount(rig.localClock), 2);
    },
  );
}
