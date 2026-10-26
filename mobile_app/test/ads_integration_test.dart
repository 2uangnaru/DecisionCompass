// Real ManagedAdService + AdPolicy behind the actual pages. Only the native
// SDK boundary (FakeAdsBackend) is faked, so these prove the wiring that the
// page tests with a NoOp-derived service cannot.
import 'package:decision_compass/analytics/analytics_service.dart';
import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/data/history_entry.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/data/reading_quota_controller.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/history_page.dart';
import 'package:decision_compass/pages/home_page.dart';
import 'package:decision_compass/pages/loading_page.dart';
import 'package:decision_compass/pages/result_page.dart';
import 'package:decision_compass/pages/ritual_page.dart';
import 'package:decision_compass/services/ad_policy.dart';
import 'package:decision_compass/services/ad_service.dart';
import 'package:decision_compass/widgets/celestial_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ads_test_fakes.dart';
import 'analytics/analytics_flow_test.dart' show RecordingAnalytics;
import 'reading_test_rig.dart';

final _profile = AppProfile(
  userName: 'Alex',
  birthDate: DateTime(2001, 2, 12),
  birthCountryCode: 'VN',
  zodiacSign: ZodiacSign.aquarius,
  useCurrentLocation: false,
  safetyAcknowledged: true,
);

class _Env {
  DateTime local = DateTime(2026, 10, 26, 9);
  final backend = FakeAdsBackend();
  final store = MemoryAdPolicyStore();
  late final ads = ManagedAdService(
    backend: backend,
    policy: AdPolicy(store: store),
    nowLocal: () => local,
    nowUtc: () => local.toUtc(),
  );

  ReadingTestRig rig({
    ReadingQuotaController quota = const NoopReadingQuotaController(),
    AnalyticsService analytics = const NoopAnalyticsService(),
  }) => ReadingTestRig(
    response: fixtureResponse('ready_yes_no_now.json'),
    localNow: local,
    liveLocalClock: () => local,
    quotaManager: quota,
    adService: ads,
    analytics: analytics,
  );

  /// Yesterday's view: today's first-daily protection is still in force.
  void viewedYesterday() => store.day = '2026-10-25';
  void viewedToday() => store.day = AdPolicy.dayKey(local);
}

Widget _loading(ReadingTestRig rig) => localizedApp(
  home: LoadingPage(
    mode: DecisionMode.yesNo,
    period: TimePeriod.now,
    category: engine.ReadingCategory.general,
    profile: _profile,
    instantUtc: rig.revealInstant,
    dependencies: rig.dependencies,
  ),
);

Future<void> _toAnalysisEnd(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 5400));
  await tester.pump();
}

Future<void> _settleResult(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

Future<void> _saveSnapshot(ReadingTestRig rig) => rig.historyRepository.save(
  HistoryEntry(
    id: 'snapshot',
    reading: fixtureResponse('ready_yes_no_now.json'),
    savedAtUtc: DateTime.utc(2026, 10, 25),
  ),
);

/// Dispose the service's own timers before the widget-test invariants run.
Future<void> _run(
  WidgetTester tester,
  _Env env,
  Future<void> Function() body,
) async {
  try {
    await env.ads.initialize();
    await body();
  } finally {
    env.ads.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }
}

void main() {
  setUpAll(loadBundledFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'A: a viewed Result makes the next FREE reading and History eligible',
    (tester) async {
      final env = _Env();
      final quota = SharedPreferencesReadingQuotaController();
      await _run(tester, env, () async {
        final first = env.backend.ready(AdFormat.interstitial);
        await tester.pumpWidget(_loading(env.rig(quota: quota)));
        await _toAnalysisEnd(tester);
        await _settleResult(tester);
        expect(find.byType(ResultPage), findsOneWidget);
        expect(first.showCount, 0);
        // Marked by the Result's first frame, which is what unlocks later ads.
        expect(env.store.day, '2026-10-26');

        env.local = env.local.add(const Duration(hours: 3, minutes: 1));
        // Three hours outlives the 50-minute cache: the expired ad is never
        // shown, and a refresh supplies the one that is.
        env.ads.preloadInterstitial();
        expect(first.disposeCount, 1);
        final fresh = env.backend.ready(AdFormat.interstitial);
        final rig = env.rig(quota: quota);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(_loading(rig));
        await _toAnalysisEnd(tester);
        expect(first.showCount, 0);
        expect(fresh.showCount, 1);
        expect(find.byType(ResultPage), findsNothing);
        fresh.close();
        await _settleResult(tester);
        expect(find.byType(ResultPage), findsOneWidget);
        expect(env.store.dismissed, env.local.toUtc().millisecondsSinceEpoch);

        // History shares the 30-second gap: inside it the snapshot opens
        // at once, after it the tap is an ad candidate.
        final next = env.backend.ready(AdFormat.interstitial);
        await tester.pumpWidget(
          localizedApp(home: HistoryPage(dependencies: rig.dependencies)),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(GlassCard).first);
        await tester.pumpAndSettle();
        expect(next.showCount, 0);
        expect(find.byType(ResultPage), findsOneWidget);
        final back = find.byKey(const Key('result_history_action'));
        await tester.ensureVisible(back);
        await tester.tap(back);
        await tester.pumpAndSettle();
        env.local = env.local.add(const Duration(seconds: 30));
        await tester.tap(find.byType(GlassCard).first);
        await tester.pump();
        expect(next.showCount, 1);
        expect(find.byType(ResultPage), findsNothing);
        next.close();
        await tester.pumpAndSettle();
        expect(find.byType(ResultPage), findsOneWidget);
      });
    },
  );

  testWidgets('B: the first reading and its own History branch stay clean', (
    tester,
  ) async {
    final env = _Env();
    final quota = SharedPreferencesReadingQuotaController();
    await _run(tester, env, () async {
      final ad = env.backend.ready(AdFormat.interstitial);
      final rig = env.rig(quota: quota);
      await tester.pumpWidget(_loading(rig));
      await _toAnalysisEnd(tester);
      await _settleResult(tester);
      // The policy alone would now allow History: the flag is what protects.
      expect(env.store.day, '2026-10-26');
      final history = find.byKey(const Key('result_history_action'));
      await tester.ensureVisible(history);
      await tester.tap(history);
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byType(GlassCard).first);
        await tester.pumpAndSettle();
        expect(
          tester.widget<ResultPage>(find.byType(ResultPage)).autoSave,
          false,
        );
        final back = find.byKey(const Key('result_history_action'));
        await tester.ensureVisible(back);
        await tester.tap(back);
        await tester.pumpAndSettle();
      }
      expect(ad.showCount, 0);
      expect(env.ads.isInterstitialLoaded, true);
      expect(rig.repository.requests, hasLength(1));
      expect(rig.historyRepository.saved, hasLength(1));
    });
  });

  testWidgets('C: History from Home before today\'s first reading is clean', (
    tester,
  ) async {
    final env = _Env()..viewedYesterday();
    await _run(tester, env, () async {
      final ad = env.backend.ready(AdFormat.interstitial);
      final rig = env.rig();
      await _saveSnapshot(rig);
      await tester.pumpWidget(
        localizedApp(home: HistoryPage(dependencies: rig.dependencies)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(GlassCard).first);
      await tester.pumpAndSettle();
      expect(find.byType(ResultPage), findsOneWidget);
      expect(ad.showCount, 0);
      expect(env.ads.isInterstitialLoaded, true);
      expect(rig.repository.requests, isEmpty);
    });
  });

  for (final option in ['mode', 'category', 'period']) {
    testWidgets('D: $option unlock comes only from the earned callback', (
      tester,
    ) async {
      useScreen(tester, size: const Size(393, 900));
      final env = _Env();
      final analytics = RecordingAnalytics();
      final quota = FakeReadingQuotaController(initialCooldown: true);
      final rig = env.rig(quota: quota, analytics: analytics);
      await _run(tester, env, () async {
        await tester.pumpWidget(
          localizedApp(
            home: option == 'period'
                ? RitualPage(
                    mode: DecisionMode.yesNo,
                    period: TimePeriod.now,
                    category: engine.ReadingCategory.general,
                    profile: _profile,
                    dependencies: rig.dependencies,
                  )
                : HomePage(profile: _profile, dependencies: rig.dependencies),
          ),
        );
        await tester.pump();
        final target = switch (option) {
          'mode' => find.text('STAY'),
          'category' => find.byKey(const Key('category_love')),
          _ => find.byKey(const Key('ritual_period_evening')),
        };
        final unlock = find.byKey(const Key('option_unlock_ad_button'));
        final notReady = find.text(rig.strings.adNotReady);
        int granted() =>
            analytics.events.where((e) => e.name == 'reward_granted').length;
        Future<void> ask() async {
          await tester.ensureVisible(target);
          await tester.tap(target);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(unlock, findsOneWidget);
          await tester.tap(unlock);
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pump(const Duration(milliseconds: 400));
        }

        Future<void> clearNotice() async {
          for (var i = 0; i < 8; i++) {
            await tester.pump(const Duration(seconds: 1));
          }
          expect(notReady, findsNothing);
        }

        // Missing ad: the first rewarded load has not answered.
        await ask();
        expect(notReady, findsOneWidget);
        expect(granted(), 0);
        await clearNotice();

        // Closed without earning.
        var ad = env.backend.ready(AdFormat.rewarded);
        await ask();
        expect(ad.showCount, 1);
        ad.close();
        await tester.pump();
        expect(granted(), 0);
        expect(notReady, findsNothing);

        // Failed to show.
        ad = env.backend.ready(AdFormat.rewarded);
        await ask();
        ad.fail();
        await tester.pump();
        expect(granted(), 0);
        expect(notReady, findsOneWidget);
        await clearNotice();

        // Earned, delivered twice: unlocked once.
        ad = env.backend.ready(AdFormat.rewarded);
        await ask();
        ad.reward();
        ad.reward();
        ad.close();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(granted(), 1);
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(unlock, findsNothing);
        expect(quota.bonusReadings, 0);
      });
      analytics.dispose();
    });
  }

  testWidgets('E: a bonus-funded analysis never shows an interstitial', (
    tester,
  ) async {
    final env = _Env()..viewedToday();
    final quota = SharedPreferencesReadingQuotaController();
    await quota.consumeReading(env.local);
    await quota.earnBonusReading();
    await _run(tester, env, () async {
      final ad = env.backend.ready(AdFormat.interstitial);
      final rig = env.rig(quota: quota);
      env.local = env.local.add(const Duration(minutes: 10));
      await tester.pumpWidget(_loading(rig));
      await _toAnalysisEnd(tester);
      await _settleResult(tester);
      expect(find.byType(ResultPage), findsOneWidget);
      expect(quota.bonusReadings, 0);
      expect(quota.dailyCompletedReadingsCount(env.local), 2);
      expect(ad.showCount, 0);
      expect(env.ads.isInterstitialLoaded, true);
    });
  });

  testWidgets(
    'F: rapid History taps show one ad; leaving during it opens nothing',
    (tester) async {
      final env = _Env()..viewedToday();
      await _run(tester, env, () async {
        final ad = env.backend.ready(AdFormat.interstitial);
        final rig = env.rig();
        await _saveSnapshot(rig);
        await tester.pumpWidget(
          localizedApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          HistoryPage(dependencies: rig.dependencies),
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
        for (var i = 0; i < 10; i++) {
          await tester.tap(find.byType(GlassCard).first, warnIfMissed: false);
        }
        await tester.pump();
        expect(ad.showCount, 1);
        await tester.pageBack();
        await tester.pumpAndSettle();
        ad.close();
        await tester.pumpAndSettle();
        expect(find.text('open'), findsOneWidget);
        expect(find.byType(ResultPage), findsNothing);
        // Nothing was queued: a newly ready ad is never shown by itself.
        final next = env.backend.ready(AdFormat.interstitial);
        await tester.pump(const Duration(minutes: 1));
        expect(next.showCount, 0);
        expect(find.byType(ResultPage), findsNothing);
      });
    },
  );

  testWidgets('F: Loading disposed during its ad never pushes a Result', (
    tester,
  ) async {
    final env = _Env()..viewedToday();
    final quota = SharedPreferencesReadingQuotaController();
    await quota.consumeReading(env.local.subtract(const Duration(hours: 4)));
    await _run(tester, env, () async {
      final ad = env.backend.ready(AdFormat.interstitial);
      await tester.pumpWidget(_loading(env.rig(quota: quota)));
      await _toAnalysisEnd(tester);
      expect(ad.showCount, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      ad.close();
      await tester.pumpAndSettle();
      expect(find.byType(ResultPage), findsNothing);
      // The native dismissal still starts the shared gap.
      expect(env.store.dismissed, isNotNull);
    });
  });
}
