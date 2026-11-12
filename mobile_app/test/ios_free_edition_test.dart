import 'dart:convert';

import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/billing/plus_entitlement.dart';
import 'package:decision_compass/data/guidance_lock_store.dart';
import 'package:decision_compass/data/reading_quota_controller.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/monetization_policy.dart';
import 'package:decision_compass/pages/home_page.dart';
import 'package:decision_compass/pages/loading_page.dart';
import 'package:decision_compass/pages/result_page.dart';
import 'package:decision_compass/pages/ritual_page.dart';
import 'package:decision_compass/services/ad_service.dart';
import 'package:decision_compass/widgets/ad_banner_slot.dart';
import 'package:decision_compass/widgets/astracue_plus_ui.dart';
import 'package:decision_compass/widgets/celestial_ui.dart';
import 'package:decision_compass/widgets/responsible_use_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tool/ios_release_config.dart';
import 'plus_billing_test.dart' show FakePlusStore, FakeVerifier;
import 'reading_flow_test.dart' show pumpPastRitual;
import 'reading_test_rig.dart';

class _SpyAds extends NoOpAdService {
  int interstitials = 0, rewards = 0;
  @override
  Future<void> showInterstitial({
    required VoidCallback onDismissed,
    InterstitialPlacement placement = InterstitialPlacement.afterAnalysis,
  }) async {
    interstitials++;
    onDismissed();
  }

  @override
  Future<AdOutcome> showRewarded({
    required Future<void> Function() onEarnedReward,
    String placement = 'reading',
  }) async {
    rewards++;
    return AdOutcome.skipped;
  }
}

final _profile = AppProfile(
  birthDate: DateTime(2001, 2, 12),
  birthCountryCode: 'VN',
  zodiacSign: ZodiacSign.aquarius,
  useCurrentLocation: false,
  safetyAcknowledged: true,
);

Future<void> _capture(Finder screen, String name) async {
  if (const bool.fromEnvironment('CAPTURE_FREE_EDITION_UI')) {
    await expectLater(
      screen,
      matchesGoldenFile('../build/ios-free-review/$name.png'),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadBundledFonts();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'only iOS defaults to the free edition; explicit re-enable is possible',
    () {
      expect(MonetizationPolicy.enabledFor(TargetPlatform.iOS), false);
      expect(MonetizationPolicy.enabledFor(TargetPlatform.android), true);
      expect(
        MonetizationPolicy.enabledFor(TargetPlatform.iOS, iosEnabled: true),
        true,
      );
      expect(
        MonetizationPolicy.enabledFor(
          TargetPlatform.android,
          iosEnabled: false,
        ),
        true,
      );
    },
  );

  test('disabled dependency boundary neither spends saved quota nor alters VIP/guidance records', () async {
    final now = DateTime(2026, 11, 12, 9);
    final quota = SharedPreferencesReadingQuotaController(
      cooldownDuration: Duration.zero,
    );
    await quota.ensureLoaded();
    for (var i = 0; i < 3; i++) {
      await quota.consumeReading(now);
    }
    expect(quota.isAvailable(now), false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      PlusEntitlementController.storageKey,
      jsonEncode({
        'active': true,
        'proof': {
          'productId': 'astracue_plus_lifetime',
          'purchaseId': '12345',
          'serverVerificationData': 'existing-proof',
          'source': 'app_store',
        },
      }),
    );
    await prefs.setInt(GuidanceLockStore.countKey, 12);
    await prefs.setStringList(GuidanceLockStore.lockedKey, [
      'existing-guidance',
    ]);
    final store = FakePlusStore();
    final plus = PlusEntitlementController(
      store: store,
      verifier: FakeVerifier(),
      productId: 'astracue_plus_lifetime',
    );
    await plus.loadCached();
    expect(plus.isActive, true);
    final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
    final ads = _SpyAds();
    final rig = ReadingTestRig(
      quotaManager: quota,
      adService: ads,
      plus: plus,
      guidanceLocks: GuidanceLockStore(),
      monetizationEnabled: false,
    );
    expect(rig.dependencies.plus, isNull);
    expect(rig.dependencies.plusActive, false);
    expect(rig.dependencies.guidanceLocks, isNull);
    for (var i = 0; i < 10; i++) {
      expect(rig.dependencies.quotaManager.isAvailable(now), true);
      await rig.dependencies.quotaManager.consumeReading(now);
    }
    expect(rig.dependencies.quotaManager.isCooldown(now), false);
    expect(
      await rig.dependencies.adService.showRewarded(
        onEarnedReward: () async => fail('must never grant a fake reward'),
      ),
      AdOutcome.skipped,
    );
    await rig.dependencies.adService.showInterstitial(onDismissed: () {});
    expect(ads.rewards + ads.interstitials, 0);
    expect(plus.isActive, true);
    expect(quota.dailyFreeReadingsUsed(now), 3);
    expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
    plus.dispose();
    quota.dispose();
    await store.controller.close();
  });

  test('free iOS release needs no product/ad configuration; conflicting ad flags fail', () {
    final config = <String, Object?>{
      'IOS_BUNDLE_ID': 'com.astracue.freeapp',
      'IOS_DEVELOPMENT_TEAM': 'ABCDE12345',
      'IOS_PLUS_PRODUCT_ID': '',
      'IOS_MONETIZATION_ENABLED': false,
      'PRIVACY_POLICY_URL': 'https://astracue.app/privacy',
      'TERMS_OF_USE_URL': 'https://astracue.app/terms',
      'SUPPORT_URL': 'https://astracue.app/support',
      'IOS_ADS_ENABLED': false,
      'IOS_TRACKING_ENABLED': false,
      'FIREBASE_ANALYTICS_ENABLED': false,
      'PLUS_DEMO_BILLING': false,
    };
    expect(validateIOSReleaseConfig(config), isEmpty);
    expect(
      validateIOSReleaseConfig({...config, 'IOS_MONETIZATION_ENABLED': true}),
      isNotEmpty,
    );
    expect(
      validateIOSReleaseConfig({...config, 'IOS_ADS_ENABLED': true}),
      isNotEmpty,
    );
    expect(
      validateIOSReleaseConfig({...config, 'IOS_TRACKING_ENABLED': true}),
      isNotEmpty,
    );
  });

  for (final locale in AppLocale.values) {
    testWidgets(
      'free Home fits ${locale.tag} without commercial widgets or locks',
      (tester) async {
        useScreen(tester, size: const Size(360, 740), textScale: 1.5);
        final ads = _SpyAds();
        final rig = ReadingTestRig(
          locale: locale,
          adService: ads,
          quotaManager: FakeReadingQuotaController(
            initialCooldown: true,
            initialUsed: 3,
          ),
          monetizationEnabled: false,
        );
        rig.dailyBriefProvider.response = engine.DailyBrief(
          luckyNumber: 9,
          colors: testDailyColors(),
          energy: const engine.DailyEnergy(
            level: 'steady',
            index: 50,
            dataCoverage: 1,
          ),
        );
        await tester.pumpWidget(
          localizedApp(
            locale: locale,
            home: HomePage(profile: _profile, dependencies: rig.dependencies),
          ),
        );
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 40));
        }
        expect(find.byType(AstraCuePlusHeaderBadge), findsNothing);
        expect(find.byType(HomeEmbeddedEnergyTray), findsNothing);
        expect(find.byType(AdBannerSlot), findsNothing);
        expect(find.byType(AdOptionBadge), findsNothing);
        expect(find.byKey(const Key('daily_auspicious_hour')), findsOneWidget);
        expect(find.byKey(const Key('find_direction')), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(ads.rewards + ads.interstitials, 0);
        await _capture(find.byType(HomePage), 'home_${locale.tag}');
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'free Reveal ignores old exhausted overrides, retains real period cutoffs and reaches Result',
    (tester) async {
      useScreen(tester, size: const Size(393, 900));
      final ads = _SpyAds();
      final quota = FakeReadingQuotaController(
        initialCooldown: true,
        initialUsed: 3,
      );
      final rig = ReadingTestRig(
        response: fixtureResponse('ready_yes_no_now.json'),
        adService: ads,
        quotaManager: quota,
        monetizationEnabled: false,
        localNow: DateTime(2026, 9, 18, 14),
      );
      await tester.pumpWidget(
        localizedApp(
          home: RitualPage(
            mode: DecisionMode.yesNo,
            period: TimePeriod.now,
            category: engine.ReadingCategory.general,
            profile: _profile,
            dependencies: rig.dependencies,
            isCooldown: true,
            isQuotaExhausted: true,
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byKey(const Key('ritual_quota_badge')), findsNothing);
      expect(find.byKey(const Key('ritual_watch_ad_button')), findsNothing);
      expect(find.byKey(const Key('ritual_energy_plus_card')), findsNothing);
      expect(find.byType(AdBannerSlot), findsNothing);
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const Key('ritual_period_morning')))
            .onSelected,
        isNull,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const Key('ritual_period_now')))
            .selected,
        true,
      );
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const Key('ritual_period_afternoon')),
            )
            .onSelected,
        isNotNull,
      );
      await _capture(find.byType(RitualPage), 'reveal');
      await tester.tap(find.byKey(const Key('reveal_button')));
      await tester.pump(const Duration(milliseconds: 380));
      await pumpPastRitual(tester);
      expect(find.byType(ResultPage), findsOneWidget);
      expect(find.byType(AnalysisEnergyPlusCard), findsNothing);
      expect(
        find.byKey(const Key('result_guidance_watch_ad_button')),
        findsNothing,
      );
      expect(rig.historyRepository.saved, hasLength(1));
      expect(quota.dailyFreeReadingsUsed(rig.localClock), 3);
      expect(ads.rewards + ads.interstitials, 0);
      await _capture(find.byType(ResultPage), 'result');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'free historical guidance is readable without permanently unlocking its paid record',
    (tester) async {
      final reading = fixtureResponse('ready_yes_no_now.json');
      final key = '${reading.readingKey!}|${reading.mode.toJson()}';
      SharedPreferences.setMockInitialValues({
        GuidanceLockStore.countKey: 12,
        GuidanceLockStore.lockedKey: [key],
      });
      final rig = ReadingTestRig(
        guidanceLocks: GuidanceLockStore(),
        monetizationEnabled: false,
      );
      await tester.pumpWidget(
        localizedApp(
          home: ResultPage(
            reading: reading,
            dependencies: rig.dependencies,
            autoSave: false,
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
      expect(
        find.byKey(const Key('result_guidance_watch_ad_button')),
        findsNothing,
      );
      expect(find.byType(AnalysisEnergyPlusCard), findsNothing);
      expect(
        find
            .byType(ImageFiltered)
            .evaluate()
            .where((e) => (e.widget as ImageFiltered).enabled),
        isEmpty,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(GuidanceLockStore.lockedKey), [key]);
      expect(prefs.getInt(GuidanceLockStore.countKey), 12);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('free edition keeps first-reading responsible-use gate', (
    tester,
  ) async {
    useScreen(tester, size: const Size(393, 900));
    final rig = ReadingTestRig(
      response: fixtureResponse('ready_yes_no_now.json'),
      monetizationEnabled: false,
    );
    await tester.pumpWidget(
      localizedApp(
        home: RitualPage(
          mode: DecisionMode.yesNo,
          period: TimePeriod.now,
          category: engine.ReadingCategory.general,
          profile: _profile.copyWith(safetyAcknowledged: false),
          dependencies: rig.dependencies,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('reveal_button')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ResponsibleUseSheet), findsOneWidget);
    expect(find.byType(LoadingPage), findsNothing);
    expect(rig.repository.requests, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
