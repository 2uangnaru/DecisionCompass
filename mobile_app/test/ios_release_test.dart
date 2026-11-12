import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:decision_compass/analytics/analytics_service.dart';
import 'package:decision_compass/app_locale.dart';
import 'package:decision_compass/app_profile.dart';
import 'package:decision_compass/billing/plus_billing.dart';
import 'package:decision_compass/billing/plus_entitlement.dart';
import 'package:decision_compass/l10n/app_localizations.dart';
import 'package:decision_compass/data/models/models.dart' as engine;
import 'package:decision_compass/models.dart' show ZodiacSign;
import 'package:decision_compass/pages/home_page.dart';
import 'package:decision_compass/pages/legal_page.dart';
import 'package:decision_compass/services/ad_service.dart';
import 'package:decision_compass/widgets/astracue_plus_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tool/ios_release_config.dart';
import 'plus_billing_test.dart' show FakePlusStore, FakeVerifier, RecordingAds;
import 'reading_test_rig.dart';

const _product = 'astracue_plus_lifetime';
const _proof = PlusPurchaseProof(
  productId: _product,
  purchaseId: '12345',
  serverVerificationData: 'not-trusted-as-verification',
  source: 'app_store',
);
const _snapshot = ReadingEnergySnapshot(
  usedFreeTurns: 0,
  remainingFreeTurns: 3,
  cooldownRemaining: Duration.zero,
  timeUntilMidnight: Duration(hours: 8),
);

Map<String, Object?> _configuration() => {
  'IOS_BUNDLE_ID': 'com.astracue.testapp',
  'IOS_DEVELOPMENT_TEAM': 'ABCDE12345',
  'IOS_PLUS_PRODUCT_ID': _product,
  'IOS_MONETIZATION_ENABLED': true,
  'PRIVACY_POLICY_URL': 'https://astracue.app/privacy',
  'TERMS_OF_USE_URL': 'https://astracue.app/terms',
  'SUPPORT_URL': 'https://astracue.app/support',
  'IOS_ADS_ENABLED': false,
  'IOS_TRACKING_ENABLED': false,
  'FIREBASE_ANALYTICS_ENABLED': false,
  'PLUS_DEMO_BILLING': false,
};

class _SyncStore extends FakePlusStore implements PlusPurchaseSynchronizer {
  @override
  bool get requiresSynchronization => true;
  int syncs = 0;
  bool failSync = false;
  Completer<void>? syncGate;
  @override
  Future<void> synchronizePurchases() async {
    syncs++;
    if (failSync) throw StateError('sync_failed');
    await syncGate?.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('astracue/ios');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const verifier = IOSStoreKitPlusVerifier(productId: _product);

  setUpAll(loadBundledFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  group('StoreKit verification boundary', () {
    test(
      'timed-out StoreKit sync keeps ads guarded until native completion',
      () async {
        final store = _SyncStore();
        final ads = RecordingAds();
        final plus = PlusEntitlementController(
          store: store,
          verifier: verifier,
          productId: _product,
          ads: ads,
          requireSupportedSaleClaims: false,
          storeTimeout: const Duration(milliseconds: 30),
        );
        addTearDown(() async {
          plus.dispose();
          await store.controller.close();
        });
        await plus.start();
        store.syncGate = Completer<void>();
        expect(await plus.restore(), PlusRestoreResult.failed);
        expect(ads.claims, 1);
        expect(ads.releases, 0);
        store.syncGate!.complete();
        await Future<void>.delayed(Duration.zero);
        expect(ads.releases, 1);
        expect(plus.isActive, false);
      },
    );
    test(
      'explicit StoreKit sync shares the fullscreen guard with ads',
      () async {
        final store = _SyncStore();
        final ads = RecordingAds();
        final plus = PlusEntitlementController(
          store: store,
          verifier: verifier,
          productId: _product,
          ads: ads,
          requireSupportedSaleClaims: false,
        );
        addTearDown(() async {
          plus.dispose();
          await store.controller.close();
        });
        await plus.start();
        ads.busy = true;
        expect(await plus.restore(), PlusRestoreResult.failed);
        expect(store.syncs, 0);
        ads.busy = false;
        expect(await plus.restore(), PlusRestoreResult.nothingToRestore);
        expect(store.syncs, 1);
        expect(ads.claims, 1);
        expect(ads.releases, 1);
      },
    );
    test(
      'only explicit Restore syncs; canceled/failed sync returns to idle',
      () async {
        final store = _SyncStore();
        final plus = PlusEntitlementController(
          store: store,
          verifier: verifier,
          productId: _product,
          requireSupportedSaleClaims: false,
        );
        addTearDown(() async {
          plus.dispose();
          await store.controller.close();
        });
        await plus.start();
        expect(store.syncs, 0);
        expect(await plus.restore(), PlusRestoreResult.nothingToRestore);
        expect(store.syncs, 1);
        store.failSync = true;
        expect(await plus.restore(), PlusRestoreResult.failed);
        expect(plus.checkout, PlusCheckoutState.idle);
        expect(plus.isActive, false);
      },
    );
    for (final status in ['revoked', 'unavailable']) {
      test(
        'cached entitlement on native $status is reconciled safely',
        () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            PlusEntitlementController.storageKey,
            jsonEncode({'active': true, 'proof': _proof.toJson()}),
          );
          messenger.setMockMethodCallHandler(
            channel,
            (_) async => {
              'productId': _product,
              'purchaseId': '12345',
              'status': status,
            },
          );
          final store = FakePlusStore();
          final plus = PlusEntitlementController(
            store: store,
            verifier: verifier,
            productId: _product,
            requireSupportedSaleClaims: false,
          );
          addTearDown(() async {
            plus.dispose();
            await store.controller.close();
          });
          await plus.start();
          expect(plus.isActive, status != 'revoked');
        },
      );
    }
    for (final verdict in {
      'valid': PlusVerdict.valid,
      'invalid': PlusVerdict.invalid,
      'revoked': PlusVerdict.revoked,
      'unavailable': PlusVerdict.unavailable,
      'unexpected': PlusVerdict.unavailable,
    }.entries) {
      test('native ${verdict.key} maps without trusting a receipt', () async {
        messenger.setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'verifyPlusPurchase');
          expect(call.arguments, {
            'productId': _product,
            'purchaseId': '12345',
          });
          return {
            'productId': _product,
            'purchaseId': '12345',
            'status': verdict.key,
          };
        });
        expect(await verifier.verify(_proof), verdict.value);
      });
    }
    test('mismatched IDs, malformed, missing and throwing native handlers fail closed', () async {
      for (final response in [
        {'productId': 'another', 'purchaseId': '12345', 'status': 'valid'},
        {'productId': _product, 'purchaseId': '54321', 'status': 'valid'},
        {'status': 'valid'},
        'valid',
        null,
      ]) {
        messenger.setMockMethodCallHandler(channel, (_) async => response);
        expect(await verifier.verify(_proof), PlusVerdict.unavailable);
      }
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: 'unavailable'),
      );
      expect(await verifier.verify(_proof), PlusVerdict.unavailable);
      messenger.setMockMethodCallHandler(channel, null);
      expect(await verifier.verify(_proof), PlusVerdict.unavailable);
    });
    test('foreign stores, products and invalid transaction IDs never reach native verification', () async {
      var calls = 0;
      messenger.setMockMethodCallHandler(channel, (_) async {
        calls++;
        return null;
      });
      for (final proof in [
        const PlusPurchaseProof(
          productId: _product,
          purchaseId: '12345',
          serverVerificationData: '',
          source: 'google_play',
        ),
        const PlusPurchaseProof(
          productId: 'another',
          purchaseId: '12345',
          serverVerificationData: '',
          source: 'app_store',
        ),
        const PlusPurchaseProof(
          productId: _product,
          purchaseId: 'fake',
          serverVerificationData: '',
          source: 'app_store',
        ),
        const PlusPurchaseProof(
          productId: _product,
          purchaseId: null,
          serverVerificationData: '',
          source: 'app_store',
        ),
      ]) {
        expect(await verifier.verify(proof), PlusVerdict.invalid);
      }
      expect(calls, 0);
    });
    test('factory selects StoreKit on iOS and leaves Android fail-closed', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(
        plusVerifierFor(const PlusBillingConfig(productId: _product)),
        isA<IOSStoreKitPlusVerifier>(),
      );
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(
        plusVerifierFor(const PlusBillingConfig(productId: _product)),
        isA<UnconfiguredPlusVerifier>(),
      );
    });
    test('controller grants only after native verification and completes the purchase', () async {
      final store = FakePlusStore();
      final plus = PlusEntitlementController(
        store: store,
        verifier: verifier,
        productId: _product,
        requireSupportedSaleClaims: false,
      );
      addTearDown(() async {
        plus.dispose();
        await store.controller.close();
      });
      await plus.start();
      expect(plus.isActive, false);
      store.emit(
        const PlusPurchaseUpdate(
          productId: _product,
          status: PlusPurchaseStatus.pending,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(plus.isActive, false);
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => {
          'productId': _product,
          'purchaseId': '12345',
          'status': 'valid',
        },
      );
      const purchased = PlusPurchaseUpdate(
        productId: _product,
        status: PlusPurchaseStatus.purchased,
        proof: _proof,
        needsCompletion: true,
      );
      store.emit(purchased);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(plus.isActive, true);
      expect(store.completed, hasLength(1));
    });
  });

  test(
    'iOS first launch is opt-in; saved consent and Android default survive',
    () async {
      const ios = SharedPreferencesAnalyticsConsentStore(defaultEnabled: false);
      expect(await ios.load(), false);
      expect(await const SharedPreferencesAnalyticsConsentStore().load(), true);
      await ios.save(true);
      expect(await ios.load(), true);
      await ios.save(false);
      expect(await ios.load(), false);
    },
  );

  test(
    'iOS store ads cannot fall back to Google samples or malformed units',
    () {
      for (final id in ['', AdConstants.testIosRewardedUnitId, 'malformed']) {
        expect(
          AdConstants.iosUnit(
            configured: id,
            test: AdConstants.testIosRewardedUnitId,
            release: true,
            enabled: true,
          ),
          isEmpty,
        );
      }
      const liveShape = 'ca-app-pub-1234567890123456/1234567890';
      expect(
        AdConstants.iosUnit(
          configured: liveShape,
          test: '',
          release: true,
          enabled: false,
        ),
        isEmpty,
      );
      expect(
        AdConstants.iosUnit(
          configured: liveShape,
          test: '',
          release: true,
          enabled: true,
        ),
        liveShape,
      );
      expect(
        AdConstants.iosUnit(
          configured: '',
          test: AdConstants.testIosRewardedUnitId,
          release: false,
        ),
        AdConstants.testIosRewardedUnitId,
      );
    },
  );

  group('release preflight', () {
    test('valid structure generates matching native product and safe HTTPS settings', () {
      expect(validateIOSReleaseConfig(_configuration()), isEmpty);
      final native = iosOwnerXcconfig(_configuration());
      expect(native, contains('ASTRACUE_PLUS_PRODUCT_ID = $_product'));
      expect(native, contains(r'https:/$()/astracue.app/privacy'));
      expect(native, isNot(contains('3940256099942544')));
    });
    test('rejects unfilled IDs, demo billing, URLs and xcconfig injection', () {
      for (final change in <Map<String, Object?>>[
        {'IOS_BUNDLE_ID': ''},
        {'IOS_DEVELOPMENT_TEAM': ''},
        {'IOS_PLUS_PRODUCT_ID': ''},
        {'PLUS_DEMO_BILLING': true},
        {'PRIVACY_POLICY_URL': 'http://astracue.test/privacy'},
        {'TERMS_OF_USE_URL': 'https://example.com/terms'},
        {'SUPPORT_URL': 'https://a.test/\n#include "evil"'},
        {'SUPPORT_URL': r'https://a.test/$(BUILD_SETTING)'},
        {'SUPPORT_URL': 'https://a.test/"unsafe"'},
        {'IOS_TRACKING_ENABLED': true},
        {'IOS_ADS_ENABLED': 'true'},
        {
          'IOS_ADS_ENABLED': true,
          'ADMOB_IOS_APP_ID': 'ca-app-pub-3940256099942544~1458002511',
        },
      ]) {
        expect(
          validateIOSReleaseConfig({..._configuration(), ...change}),
          isNotEmpty,
          reason: change.keys.join(','),
        );
      }
    });
    test(
      'public template remains unconfigured instead of pretending to be live',
      () {
        expect(File('ios-release.example.json').existsSync(), true);
        expect(
          File('ios/Runner/PrivacyInfo.xcprivacy').readAsStringSync(),
          contains('CA92.1'),
        );
        expect(
          File('ios/Runner/AppDelegate.swift').readAsStringSync(),
          contains('case .verified(let transaction)'),
        );
      },
    );
  });

  testWidgets(
    'iOS real store price, restore and later canceled purchase have correct feedback',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      useScreen(tester);
      final store = FakePlusStore();
      final plus = PlusEntitlementController(
        store: store,
        verifier: FakeVerifier(),
        productId: _product,
        requireSupportedSaleClaims: false,
      );
      unawaited(plus.start());
      await tester.pump();
      await tester.pump();
      await tester.pumpWidget(
        localizedApp(
          home: Scaffold(
            body: AstraCuePlusSheet(
              locale: AppLocale.english,
              snapshot: _snapshot,
              plus: plus,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('119.000', findRichText: true), findsWidgets);
      expect(find.textContaining('60%'), findsNothing);
      await tester.ensureVisible(
        find.byKey(const Key('astracue_plus_restore')),
      );
      await tester.tap(find.byKey(const Key('astracue_plus_restore')));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(
        find.text('No Plus purchase was found for this store account.'),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const Key('astracue_plus_sheet_cta')),
      );
      await tester.tap(find.byKey(const Key('astracue_plus_sheet_cta')));
      await tester.pump();
      store.emit(
        const PlusPurchaseUpdate(
          productId: _product,
          status: PlusPurchaseStatus.canceled,
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.text('Purchase canceled.'), findsOneWidget);
      expect(plus.isActive, false);
      await tester.pumpWidget(const SizedBox.shrink());
      plus.dispose();
      unawaited(store.controller.close());
      await tester.pump();
      debugDefaultTargetPlatformOverride = null;
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  for (final sameDay in [true, false]) {
    testWidgets('opening prefetch is reused only on its own day: $sameDay', (
      tester,
    ) async {
      final rig = ReadingTestRig(localNow: DateTime(2026, 11, 12, 7));
      final profile = AppProfile(
        birthDate: DateTime(2001, 2, 12),
        birthCountryCode: 'VN',
        zodiacSign: ZodiacSign.aquarius,
        useCurrentLocation: false,
      );
      final oldBrief = engine.DailyBrief(
        luckyNumber: 4,
        colors: testDailyColors(),
        energy: const engine.DailyEnergy(
          level: 'steady',
          index: 50,
          dataCoverage: 1,
        ),
      );
      rig.dailyBriefProvider.response = engine.DailyBrief(
        luckyNumber: 5,
        colors: testDailyColors(),
        energy: const engine.DailyEnergy(
          level: 'radiant',
          index: 90,
          dataCoverage: 1,
        ),
      );
      await tester.pumpWidget(
        localizedApp(
          home: HomePage(
            profile: profile,
            dependencies: rig.dependencies,
            initialDailyBrief: Future.value(oldBrief),
            initialDailyBriefDate: DateTime(2026, 11, sameDay ? 12 : 11),
          ),
        ),
      );
      await tester.pump();
      expect(rig.dailyBriefProvider.previewCalls, sameDay ? 0 : 1);
      expect(find.text(sameDay ? 'STEADY' : 'RADIANT'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final locale in AppLocale.values) {
    testWidgets(
      'iOS policies and paywall fit ${locale.tag} on a narrow screen',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        useScreen(tester, size: const Size(360, 640), textScale: 1.5);
        await tester.pumpWidget(
          localizedApp(
            locale: locale,
            home: const LegalPage(document: LegalDocument.privacy),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byType(SelectableText), findsOneWidget);
        await tester.pumpWidget(
          localizedApp(
            locale: locale,
            home: const LegalPage(document: LegalDocument.terms),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          localizedApp(
            locale: locale,
            home: Scaffold(
              body: AstraCuePlusSheet(locale: locale, snapshot: _snapshot),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('legal_privacy')), findsOneWidget);
        expect(find.textContaining('60%'), findsNothing);
        // Missing store configuration is actionable feedback, never a fake purchase.
        final cta = find.byKey(const Key('astracue_plus_sheet_cta'));
        await tester.ensureVisible(cta);
        await tester.tap(cta);
        await tester.pump();
        final context = tester.element(find.byType(AstraCuePlusSheet));
        expect(
          find.text(AppLocalizations.of(context).purchaseNotAvailable),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        debugDefaultTargetPlatformOverride = null;
      },
    );
  }
}
