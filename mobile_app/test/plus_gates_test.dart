@Timeout(Duration(seconds: 90))
library;

import 'dart:async';
import 'dart:convert';

import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/billing/plus_billing.dart';
import 'package:decision_compass/billing/plus_entitlement.dart';
import 'package:decision_compass/data/guidance_lock_store.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/data/reading_quota_controller.dart';
import 'package:decision_compass/models.dart';
import 'package:decision_compass/pages/home_page.dart';
import 'package:decision_compass/pages/loading_page.dart';
import 'package:decision_compass/pages/result_page.dart';
import 'package:decision_compass/pages/ritual_page.dart';
import 'package:decision_compass/widgets/astracue_plus_ui.dart';
import 'package:decision_compass/widgets/celestial_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}
