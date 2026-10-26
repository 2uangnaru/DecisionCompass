import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/data/reading_quota_controller.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/ritual_page.dart';
import 'package:decision_compass/services/ad_policy.dart';
import 'package:decision_compass/services/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ads_test_fakes.dart';
import 'analytics/analytics_flow_test.dart' show RecordingAnalytics;
import 'reading_test_rig.dart';

class _FailingBonusQuota extends SharedPreferencesReadingQuotaController {
  int attempts = 0;
  @override
  Future<void> earnBonusReading() async {
    attempts++;
    throw StateError('disk full: /data/raw/path');
  }
}

void main() {
  final now = DateTime(2026, 10, 26, 9);
  final profile = AppProfile(
    userName: 'Alex',
    birthDate: DateTime(2001, 2, 12),
    birthCountryCode: 'VN',
    zodiacSign: ZodiacSign.aquarius,
    useCurrentLocation: false,
    safetyAcknowledged: true,
  );
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(loadBundledFonts);
  for (final earned in [false, true]) {
    testWidgets(
      'reading reward persists only from earned callback, earned=$earned',
      (tester) async {
        useScreen(tester, size: const Size(393, 900));
        final quota = SharedPreferencesReadingQuotaController();
        await quota.consumeReading(now);
        final backend = FakeAdsBackend();
        final ads = ManagedAdService(
          backend: backend,
          policy: AdPolicy(store: MemoryAdPolicyStore()),
          nowLocal: () => now,
          nowUtc: () => now.toUtc(),
        );
        try {
          await ads.initialize();
          final ad = backend.ready(AdFormat.rewarded);
          final rig = ReadingTestRig(
            localNow: now,
            quotaManager: quota,
            adService: ads,
          );
          await tester.pumpWidget(
            localizedApp(
              home: RitualPage(
                mode: DecisionMode.yesNo,
                period: TimePeriod.now,
                category: engine.ReadingCategory.general,
                profile: profile,
                dependencies: rig.dependencies,
              ),
            ),
          );
          await tester.pump();
          final button = find.byKey(const Key('ritual_watch_ad_button'));
          await tester.ensureVisible(button);
          for (var i = 0; i < 10; i++) {
            await tester.tap(button);
          }
          await tester.pump();
          expect(ad.showCount, 1);
          expect(quota.bonusReadings, 0);
          if (earned) {
            ad.reward();
            ad.reward();
            await tester.pump();
            expect(quota.bonusReadings, 1);
            // Persistence is complete while the native ad is still open.
            final restart = SharedPreferencesReadingQuotaController();
            await restart.ensureLoaded();
            expect(restart.bonusReadings, 1);
          }
          ad.close();
          await tester.pump();
          expect(quota.bonusReadings, earned ? 1 : 0);
          expect(quota.dailyCompletedReadingsCount(now), 1);
        } finally {
          ads.dispose();
          await tester.pumpWidget(const SizedBox.shrink());
        }
      },
    );
  }
  testWidgets(
    'unavailable reward leaves gate/credit unchanged and shows notice',
    (tester) async {
      useScreen(tester, size: const Size(393, 900));
      final quota = FakeReadingQuotaController(initialCooldown: true);
      final rig = ReadingTestRig(
        localNow: now,
        quotaManager: quota,
        adService: const NoOpAdService(),
      );
      await tester.pumpWidget(
        localizedApp(
          home: RitualPage(
            mode: DecisionMode.yesNo,
            period: TimePeriod.now,
            category: engine.ReadingCategory.general,
            profile: profile,
            dependencies: rig.dependencies,
          ),
        ),
      );
      await tester.pump();
      final button = find.byKey(const Key('ritual_watch_ad_button'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(quota.bonusReadings, 0);
      expect(quota.isAvailable(now), false);
      expect(find.text(rig.strings.adNotReady), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  Future<({ManagedAdService ads, FakeFullscreenAd ad})> readyAds() async {
    final backend = FakeAdsBackend();
    final ads = ManagedAdService(
      backend: backend,
      policy: AdPolicy(store: MemoryAdPolicyStore()),
      nowLocal: () => now,
      nowUtc: () => now.toUtc(),
    );
    await ads.initialize();
    return (ads: ads, ad: backend.ready(AdFormat.rewarded));
  }

  Widget ritual(ReadingTestRig rig) => localizedApp(
    home: RitualPage(
      mode: DecisionMode.yesNo,
      period: TimePeriod.now,
      category: engine.ReadingCategory.general,
      profile: profile,
      dependencies: rig.dependencies,
    ),
  );

  testWidgets('earned reward whose save fails is reported, never granted', (
    tester,
  ) async {
    useScreen(tester, size: const Size(393, 900));
    final quota = _FailingBonusQuota();
    await quota.consumeReading(now);
    final analytics = RecordingAnalytics();
    final (:ads, :ad) = await readyAds();
    try {
      final rig = ReadingTestRig(
        localNow: now,
        quotaManager: quota,
        adService: ads,
        analytics: analytics,
      );
      await tester.pumpWidget(ritual(rig));
      await tester.pump();
      final button = find.byKey(const Key('ritual_watch_ad_button'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      ad.reward();
      ad.reward();
      await tester.pump();
      ad.close();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(quota.attempts, 1);
      expect(quota.bonusReadings, 0);
      expect(find.text(rig.strings.adRewardNotSaved), findsOneWidget);
      expect(find.text(rig.strings.adNotReady), findsNothing);
      expect(find.textContaining('/data/raw'), findsNothing);
      expect(
        analytics.events.where((e) => e.name == 'reward_granted'),
        isEmpty,
      );
      expect(quota.isAvailable(now), false);
    } finally {
      ads.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 10));
      analytics.dispose();
    }
  });

  testWidgets('earned reward persists even after its route was disposed', (
    tester,
  ) async {
    useScreen(tester, size: const Size(393, 900));
    final quota = SharedPreferencesReadingQuotaController();
    await quota.consumeReading(now);
    final (:ads, :ad) = await readyAds();
    try {
      final rig = ReadingTestRig(
        localNow: now,
        quotaManager: quota,
        adService: ads,
      );
      await tester.pumpWidget(ritual(rig));
      await tester.pump();
      final button = find.byKey(const Key('ritual_watch_ad_button'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(ad.showCount, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      ad.reward();
      ad.reward();
      await tester.pump();
      final restart = SharedPreferencesReadingQuotaController();
      await restart.ensureLoaded();
      expect(restart.bonusReadings, 1);
      ad.close();
      await tester.pump();
      expect(quota.bonusReadings, 1);
      expect(tester.takeException(), isNull);
    } finally {
      ads.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
