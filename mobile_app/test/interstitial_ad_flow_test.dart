import 'dart:async';

import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/data/history_entry.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/data/reading_quota_controller.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/loading_page.dart';
import 'package:decision_compass/pages/history_page.dart';
import 'package:decision_compass/pages/result_page.dart';
import 'package:decision_compass/reading_dependencies.dart';
import 'package:decision_compass/services/ad_service.dart';
import 'package:decision_compass/widgets/celestial_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reading_test_rig.dart';

class TestAdService extends NoOpAdService {
  int initializeCalls = 0;
  int preloadCalls = 0;
  int showCalls = 0;
  int viewedCalls = 0;
  final placements = <InterstitialPlacement>[];
  Completer<void>? gate;
  bool loaded = false;

  @override
  bool get isInterstitialLoaded => loaded;

  @override
  Future<void> markReadingViewed(DateTime local) async {
    viewedCalls++;
  }

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  void preloadInterstitial() {
    preloadCalls++;
  }

  @override
  Future<void> showInterstitial({
    required VoidCallback onDismissed,
    InterstitialPlacement placement = InterstitialPlacement.afterAnalysis,
  }) async {
    showCalls++;
    placements.add(placement);
    if (gate != null) await gate!.future;
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
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
      );

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

  testWidgets('2nd reading paid by bonus: NO interstitial is triggered', (
    tester,
  ) async {
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
    // Bonus-funded analysis must not stack an interstitial onto its reward.
    expect(adService.showCalls, 0);
    expect(quota.dailyCompletedReadingsCount(rig.localClock), 2);
  });

  testWidgets(
    'second FREE reading is an afterAnalysis candidate and mark happens on Result',
    (tester) async {
      final quota = SharedPreferencesReadingQuotaController();
      final now = DateTime(2026, 10, 26, 9);
      await quota.consumeReading(now);
      final ads = TestAdService()..gate = Completer<void>();
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        localNow: now.add(const Duration(hours: 3)),
      );
      await tester.pumpWidget(
        _loadingWidget(rig: rig, quota: quota, adService: ads),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 5400));
      await tester.pump();
      expect(ads.placements, [InterstitialPlacement.afterAnalysis]);
      expect(find.byType(ResultPage), findsNothing);
      expect(ads.viewedCalls, 0);
      ads.gate!.complete();
      await _finishRitual(tester);
      expect(find.byType(ResultPage), findsOneWidget);
      expect(ads.viewedCalls, 1);
      expect(quota.dailyCompletedReadingsCount(rig.localClock), 2);
    },
  );

  testWidgets('first reading protects History replay within its own flow', (
    tester,
  ) async {
    final quota = SharedPreferencesReadingQuotaController();
    final ads = TestAdService();
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
    );
    await tester.pumpWidget(
      _loadingWidget(rig: rig, quota: quota, adService: ads),
    );
    await _finishRitual(tester);
    expect(
      tester.widget<ResultPage>(find.byType(ResultPage)).protectFirstDailyFlow,
      true,
    );
    final historyButton = find.byKey(const Key('result_history_action'));
    await tester.ensureVisible(historyButton);
    await tester.tap(historyButton);
    await tester.pumpAndSettle();
    final history = tester.widget<HistoryPage>(find.byType(HistoryPage));
    expect(history.protectFirstDailyFlow, true);
    await tester.tap(find.byType(GlassCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(ResultPage), findsOneWidget);
    expect(ads.showCalls, 0);
    expect(ads.viewedCalls, 1);
    expect(rig.repository.requests, hasLength(1));
    expect(rig.historyRepository.saved, hasLength(1));
  });

  testWidgets(
    'History opens the exact snapshot after ad; repeated taps do not queue',
    (tester) async {
      final ads = TestAdService()..gate = Completer<void>();
      final rig = ReadingTestRig();
      final reading = fixtureResponse('ready_yes_no_now.json');
      await rig.historyRepository.save(
        HistoryEntry(
          id: 'snapshot',
          reading: reading,
          savedAtUtc: DateTime.utc(2026, 10, 26),
        ),
      );
      final deps = _depsWithAd(
        rig,
        SharedPreferencesReadingQuotaController(),
        ads,
      );
      await tester.pumpWidget(
        localizedApp(home: HistoryPage(dependencies: deps)),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 10; i++) {
        await tester.tap(find.byType(GlassCard).first);
      }
      await tester.pump();
      expect(ads.placements, [InterstitialPlacement.history]);
      expect(find.byType(ResultPage), findsNothing);
      ads.gate!.complete();
      await tester.pumpAndSettle();
      final result = tester.widget<ResultPage>(find.byType(ResultPage));
      expect(identical(result.reading, reading), true);
      expect(result.autoSave, false);
      expect(rig.repository.requests, isEmpty);
      expect(rig.historyRepository.saved, hasLength(1));
      expect(ads.viewedCalls, 0);
    },
  );

  testWidgets(
    'leaving History during ad never opens a delayed snapshot on another route',
    (tester) async {
      final ads = TestAdService()..gate = Completer<void>();
      final rig = ReadingTestRig();
      await rig.historyRepository.save(
        HistoryEntry(
          id: 'snapshot',
          reading: fixtureResponse('ready_yes_no_now.json'),
          savedAtUtc: DateTime.utc(2026, 10, 26),
        ),
      );
      final deps = _depsWithAd(
        rig,
        SharedPreferencesReadingQuotaController(),
        ads,
      );
      await tester.pumpWidget(
        localizedApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => HistoryPage(dependencies: deps),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(GlassCard).first);
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      ads.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
      expect(find.byType(ResultPage), findsNothing);
    },
  );
}
