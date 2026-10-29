@Timeout(Duration(seconds: 90))
library;

import 'dart:async';
import 'dart:convert';

import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/billing/plus_billing.dart';
import 'package:decision_compass/billing/plus_entitlement.dart';
import 'package:decision_compass/data/auspicious_hour.dart';
import 'package:decision_compass/data/guidance_lock_store.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/data/reading_quota_controller.dart';
import 'package:decision_compass/l10n/app_localizations.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/home_page.dart';
import 'package:decision_compass/pages/loading_page.dart';
import 'package:decision_compass/pages/result_page.dart';
import 'package:decision_compass/pages/ritual_page.dart';
import 'package:decision_compass/services/ad_policy.dart';
import 'package:decision_compass/services/ad_runtime.dart';
import 'package:decision_compass/widgets/astracue_plus_ui.dart';
import 'package:decision_compass/widgets/celestial_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ads_test_fakes.dart' show MemoryAdPolicyStore;
import 'banner_test_fakes.dart' show FakeBannerBackend;
import 'plus_billing_test.dart'
    show FakePlusStore, FakeVerifier, RecordingAds, update;
import 'reading_test_rig.dart';

final _profile = AppProfile(
  userName: 'Alex',
  birthDate: DateTime(2001, 2, 12),
  birthCountryCode: 'VN',
  zodiacSign: ZodiacSign.aquarius,
  useCurrentLocation: false,
  safetyAcknowledged: true,
);

void main() {
  setUpAll(loadBundledFonts);
  late FakePlusStore store;
  late FakeVerifier verifier;
  late RecordingAds plusAds;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = FakePlusStore();
    verifier = FakeVerifier();
    plusAds = RecordingAds();
  });

  PlusEntitlementController controller({bool requireClaims = true}) =>
      PlusEntitlementController(
        store: store,
        verifier: verifier,
        productId: 'astracue_plus_lifetime',
        ads: plusAds,
        requireSupportedSaleClaims: requireClaims,
      );

  /// A previously verified entitlement, read the way the app reads it.
  Future<PlusEntitlementController> activePlus(WidgetTester tester) async {
    final plus = controller();
    await tester.runAsync(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        PlusEntitlementController.storageKey,
        jsonEncode({
          'active': true,
          'proof': {
            'productId': 'astracue_plus_lifetime',
            'purchaseId': 'order-1',
            'serverVerificationData': 'tok',
            'source': 'google_play',
          },
        }),
      );
      await plus.loadCached();
    });
    expect(plus.isActive, isTrue);
    return plus;
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('Home: Plus unlocks modes and categories with no ad', (
    tester,
  ) async {
    useScreen(tester, size: const Size(393, 900));
    final ads = CountingRewardAdService();
    final rig = ReadingTestRig(
      quotaManager: FakeReadingQuotaController(initialCooldown: true),
      adService: ads,
      plus: await activePlus(tester),
    );
    await tester.pumpWidget(
      localizedApp(
        home: HomePage(profile: _profile, dependencies: rig.dependencies),
      ),
    );
    await settle(tester);
    expect(find.byType(AdOptionBadge), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('category_love')));
    await tester.tap(find.byKey(const Key('category_love')));
    await settle(tester);
    expect(ads.shows, 0);
    expect(
      tester.widget<GlassCard>(find.byKey(const Key('category_love'))).selected,
      isTrue,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  Widget ritual(ReadingTestRig rig) => localizedApp(
    home: RitualPage(
      mode: DecisionMode.yesNo,
      period: TimePeriod.now,
      category: engine.ReadingCategory.general,
      profile: _profile,
      dependencies: rig.dependencies,
    ),
  );

  testWidgets('Ritual: Plus owners are never asked to watch an ad', (
    tester,
  ) async {
    useScreen(tester, size: const Size(393, 900));
    final ads = CountingRewardAdService();
    final rig = ReadingTestRig(
      quotaManager: FakeReadingQuotaController(
        initialCooldown: true,
        initialUsed: 3,
      ),
      adService: ads,
      plus: await activePlus(tester),
    );
    await tester.pumpWidget(ritual(rig));
    await settle(tester);
    expect(find.byKey(const Key('ritual_watch_ad_button')), findsNothing);
    expect(find.byType(AdOptionBadge), findsNothing);
    expect(find.byKey(const Key('ritual_energy_plus_card')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Ritual: a purchase verified mid-screen drops the ad gate', (
    tester,
  ) async {
    useScreen(tester, size: const Size(393, 900));
    final plus = controller(requireClaims: false);
    unawaited(plus.start());
    await tester.pump();
    await tester.pump();
    final rig = ReadingTestRig(
      quotaManager: FakeReadingQuotaController(initialCooldown: true),
      plus: plus,
    );
    await tester.pumpWidget(ritual(rig));
    await settle(tester);
    expect(find.byKey(const Key('ritual_watch_ad_button')), findsOneWidget);
    store.emit(update(PlusPurchaseStatus.purchased));
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    await settle(tester);
    expect(plus.isActive, isTrue);
    expect(find.byKey(const Key('ritual_watch_ad_button')), findsNothing);
    // No automatic reading: nothing navigated to Loading or spent a credit.
    expect(find.byType(LoadingPage), findsNothing);
    expect(rig.quotaManager.dailyCompletedReadingsCount(DateTime.now()), 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Result: Plus bypasses the Action Guidance ad gate for good', (
    tester,
  ) async {
    useScreen(tester, size: const Size(412, 2400));
    final reading = fixtureResponse('ready_yes_no_now.json');
    final locks = GuidanceLockStore();
    await tester.runAsync(() async {
      for (var i = 0; i < 3; i++) {
        await locks.admit('earlier_$i');
      }
    });
    final rig = ReadingTestRig(
      guidanceLocks: locks,
      plus: await activePlus(tester),
    );
    await tester.pumpWidget(
      localizedApp(
        home: ResultPage(
          reading: reading,
          dependencies: rig.dependencies,
          billableResult: true,
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 80)),
    );
    await settle(tester);
    expect(
      find.byKey(const Key('result_guidance_watch_ad_button')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('result_energy_plus_card'), skipOffstage: false),
      findsNothing,
    );
    final key = '${reading.readingKey!}|${reading.mode.toJson()}';
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(GuidanceLockStore.openKey), contains(key));
    expect(
      prefs.getStringList(GuidanceLockStore.lockedKey) ?? const <String>[],
      isNot(contains(key)),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  Future<void> openSheet(
    WidgetTester tester,
    PlusEntitlementController plus,
  ) async {
    useScreen(tester, size: const Size(393, 900));
    await tester.pumpWidget(
      localizedApp(
        home: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showAstraCuePlusSheet(
                context,
                locale: AppLocale.english,
                snapshot: ReadingEnergySnapshot.initial,
                plus: plus,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
    expect(find.byKey(const Key('astracue_plus_sheet')), findsOneWidget);
  }

  testWidgets('Sheet: store price is bound; an unsupported sale offer '
      'never reaches checkout', (tester) async {
    store.product = const PlusProduct(
      id: 'astracue_plus_lifetime',
      price: 'US\$4.99',
      currencyCode: 'USD',
      rawPrice: 4.99,
    );
    final plus = controller();
    unawaited(plus.start());
    await tester.pump();
    await tester.pump();
    await openSheet(tester, plus);
    expect(find.textContaining('US\$4.99'), findsWidgets);
    await tester.tap(find.textContaining('US\$4.99').first);
    await settle(tester);
    expect(store.buys, 0);
    expect(plus.lastBlock, PlusBlockReason.unsupportedSaleClaims);
    expect(find.byKey(const Key('astracue_plus_sheet')), findsOneWidget);
    expect(plus.isActive, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Sheet: Restore asks the store, never grants by itself', (
    tester,
  ) async {
    final plus = controller();
    unawaited(plus.start());
    await tester.pump();
    await tester.pump();
    final before = store.restores;
    await openSheet(tester, plus);
    await tester.tap(find.byKey(const Key('astracue_plus_restore')));
    await settle(tester);
    expect(store.restores, before + 1);
    expect(plus.lastRestore, PlusRestoreResult.nothingToRestore);
    expect(plus.isActive, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Banner: Plus leaves no banner or blank slot on Home and '
      'Ritual, including after a purchase mid-screen', (tester) async {
    useScreen(tester, size: const Size(393, 900));
    final ads = ManagedAdService(
      backend: FakeBannerBackend(),
      policy: AdPolicy(store: MemoryAdPolicyStore()),
    );
    final plus = controller(requireClaims: false);
    unawaited(plus.start());
    await tester.pump();
    await tester.pump();
    final rig = ReadingTestRig(
      quotaManager: FakeReadingQuotaController(),
      adService: ads,
      plus: plus,
    );
    final slot = find.byKey(const Key('banner_layout_slot'));
    await tester.pumpWidget(
      localizedApp(
        home: HomePage(profile: _profile, dependencies: rig.dependencies),
      ),
    );
    await settle(tester);
    expect(slot, findsOneWidget, reason: 'free users keep the banner slot');
    store.emit(update(PlusPurchaseStatus.purchased));
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    await settle(tester);
    expect(plus.isActive, isTrue);
    expect(slot, findsNothing);
    await tester.pumpWidget(ritual(rig));
    await settle(tester);
    expect(slot, findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    ads.dispose();
    await tester.pump();
  });

  testWidgets('VIP: Home shows the VIP badge, the real remaining credits '
      'and a computed Hoàng Đạo hour', (tester) async {
    useScreen(tester, size: const Size(393, 900));
    final rig = ReadingTestRig(
      quotaManager: _PlusQuota(initialUsed: 2),
      plus: await activePlus(tester),
    );
    await tester.pumpWidget(
      localizedApp(
        home: HomePage(profile: _profile, dependencies: rig.dependencies),
      ),
    );
    await settle(tester);
    expect(
      tester
          .widget<AstraCuePlusHeaderBadge>(find.byType(AstraCuePlusHeaderBadge))
          .isVip,
      isTrue,
    );
    final orbs = find.byType(AstralVipGoldOrbsRow, skipOffstage: false);
    expect(orbs, findsOneWidget);
    expect(tester.widget<AstralVipGoldOrbsRow>(orbs).remainingTurns, 4);
    final hour = formatAuspiciousHour(
      bestAuspiciousHourBranch(
        nowLocal: rig.dependencies.nowLocal(),
        birthDate: _profile.birthDate,
      ),
      rig.dependencies.localeController.locale,
    );
    expect(find.text(hour, skipOffstage: false), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('VIP: six of six spent reads as exhausted, with no ad', (
    tester,
  ) async {
    useScreen(tester, size: const Size(393, 900));
    final rig = ReadingTestRig(
      quotaManager: _PlusQuota(initialUsed: 6),
      plus: await activePlus(tester),
    );
    await tester.pumpWidget(ritual(rig));
    await settle(tester);
    final title = find.byKey(const Key('ritual_ready_title'));
    final l10n = AppLocalizations.of(tester.element(title));
    expect(tester.widget<Text>(title).data, l10n.dailyQuotaExhaustedTitle);
    expect(find.byKey(const Key('ritual_watch_ad_button')), findsNothing);
    expect(find.byKey(const Key('ritual_energy_plus_card')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  group('buying from any entry point runs the same flow', () {
    /// A started, purchasable controller (no sale-claim block in tests).
    Future<PlusEntitlementController> purchasable(WidgetTester tester) async {
      final plus = controller(requireClaims: false);
      unawaited(plus.start());
      await tester.pump();
      await tester.pump();
      return plus;
    }

    /// Opens the sheet through [entry], taps the real CTA, then lets the
    /// store report a completed purchase.
    Future<void> buyThrough(
      WidgetTester tester,
      PlusEntitlementController plus,
      Finder entry,
    ) async {
      await tester.ensureVisible(entry);
      await tester.tap(entry);
      await settle(tester);
      expect(find.byKey(const Key('astracue_plus_sheet')), findsOneWidget);
      await tester.tap(find.byKey(const Key('astracue_plus_sheet_cta')));
      await settle(tester);
      expect(store.buys, 1);
      expect(find.byKey(const Key('astracue_plus_sheet')), findsNothing);
      expect(plus.isActive, isFalse, reason: 'launching is not a purchase');
      store.emit(update(PlusPurchaseStatus.purchased));
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
      await settle(tester);
      expect(plus.isActive, isTrue);
      expect(plus.checkout, PlusCheckoutState.idle);
      expect(store.completed, hasLength(1));
      expect(plusAds.adFree, [true]);
    }

    testWidgets('Home header badge', (tester) async {
      useScreen(tester, size: const Size(393, 900));
      final plus = await purchasable(tester);
      final rig = ReadingTestRig(
        quotaManager: FakeReadingQuotaController(),
        plus: plus,
      );
      await tester.pumpWidget(
        localizedApp(
          home: HomePage(profile: _profile, dependencies: rig.dependencies),
        ),
      );
      await settle(tester);
      await buyThrough(tester, plus, find.byKey(const Key('home_plus_button')));
      expect(
        tester
            .widget<AstraCuePlusHeaderBadge>(
              find.byType(AstraCuePlusHeaderBadge),
            )
            .isVip,
        isTrue,
      );
      expect(
        find.byType(AstralVipGoldOrbsRow, skipOffstage: false),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Ritual energy card', (tester) async {
      useScreen(tester, size: const Size(393, 900));
      final plus = await purchasable(tester);
      final rig = ReadingTestRig(
        quotaManager: FakeReadingQuotaController(initialCooldown: true),
        plus: plus,
      );
      await tester.pumpWidget(ritual(rig));
      await settle(tester);
      expect(find.byKey(const Key('ritual_watch_ad_button')), findsOneWidget);
      await buyThrough(
        tester,
        plus,
        find.byKey(const Key('ritual_energy_plus_card')),
      );
      expect(find.byKey(const Key('ritual_energy_plus_card')), findsNothing);
      expect(find.byKey(const Key('ritual_watch_ad_button')), findsNothing);
      expect(find.byType(LoadingPage), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Result energy card, unlocking that reading\'s guidance', (
      tester,
    ) async {
      useScreen(tester, size: const Size(412, 2400));
      final plus = await purchasable(tester);
      final reading = fixtureResponse('ready_yes_no_now.json');
      final locks = GuidanceLockStore();
      await tester.runAsync(() async {
        for (var i = 0; i < 3; i++) {
          await locks.admit('earlier_$i');
        }
      });
      final rig = ReadingTestRig(guidanceLocks: locks, plus: plus);
      await tester.pumpWidget(
        localizedApp(
          home: ResultPage(
            reading: reading,
            dependencies: rig.dependencies,
            billableResult: true,
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await settle(tester);
      expect(
        find.byKey(const Key('result_guidance_watch_ad_button')),
        findsOneWidget,
      );
      // Two tappable cells with a gap between them; tap the first.
      await buyThrough(
        tester,
        plus,
        find
            .descendant(
              of: find.byKey(const Key('result_energy_plus_card')),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await settle(tester);
      expect(
        find.byKey(const Key('result_energy_plus_card'), skipOffstage: false),
        findsNothing,
      );
      expect(
        find.byKey(const Key('result_guidance_watch_ad_button')),
        findsNothing,
      );
      final key = '${reading.readingKey!}|${reading.mode.toJson()}';
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(GuidanceLockStore.openKey), contains(key));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}

/// The Plus quota's six daily credits, without the 3-hour cooldown.
class _PlusQuota extends FakeReadingQuotaController {
  _PlusQuota({super.initialUsed});
  @override
  int get maxDailyFreeReadings => 6;
}
