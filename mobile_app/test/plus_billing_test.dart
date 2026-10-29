import 'dart:async';
import 'dart:convert';

import 'package:decision_compass/billing/plus_billing.dart';
import 'package:decision_compass/billing/plus_demo.dart';
import 'package:decision_compass/billing/plus_entitlement.dart';
import 'package:decision_compass/data/reading_quota_controller.dart';
import 'package:decision_compass/services/ad_policy.dart';
import 'package:decision_compass/services/ad_runtime.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ads_test_fakes.dart';

const _id = 'astracue_plus_lifetime';

PlusPurchaseProof proof(String token) => PlusPurchaseProof(
  productId: _id,
  purchaseId: 'order-$token',
  serverVerificationData: token,
  source: 'google_play',
);

PlusPurchaseUpdate update(
  PlusPurchaseStatus status, {
  String token = 'tok',
  bool needsCompletion = true,
  PlusStoreError? error,
}) => PlusPurchaseUpdate(
  productId: _id,
  status: status,
  proof:
      status == PlusPurchaseStatus.purchased ||
          status == PlusPurchaseStatus.restored
      ? proof(token)
      : null,
  needsCompletion: needsCompletion,
  error: error,
);

/// Behaves like the real adapter: Restore always emits the (possibly empty)
/// owned list, a failed query throws, and acknowledgement reports success.
class FakePlusStore implements PlusStore {
  final controller = StreamController<List<PlusPurchaseUpdate>>.broadcast();
  bool available = true;
  bool launches = true;
  bool queryThrows = false, restoreThrows = false;
  bool ackOk = true;
  int availabilityChecks = 0, productQueries = 0;
  PlusProduct? product = const PlusProduct(
    id: _id,
    price: '119.000 ₫',
    currencyCode: 'VND',
    rawPrice: 119000,
  );

  /// What the store reports as owned on restore / startup reconciliation.
  List<PlusPurchaseUpdate> owned = [];
  int buys = 0, restores = 0;
  final completed = <PlusPurchaseUpdate>[];

  void emit(PlusPurchaseUpdate u) => controller.add([u]);

  @override
  Stream<List<PlusPurchaseUpdate>> get updates => controller.stream;
  @override
  Future<bool> isAvailable() async {
    availabilityChecks++;
    return available;
  }

  @override
  Future<PlusProduct?> queryProduct(String productId) async {
    productQueries++;
    if (queryThrows) throw StateError('query');
    return product;
  }

  @override
  Future<bool> buy(PlusProduct product) async {
    buys++;
    return launches;
  }

  @override
  Future<void> restore() async {
    restores++;
    if (restoreThrows) throw StateError('query');
    controller.add(List.of(owned));
  }

  @override
  Future<bool> complete(PlusPurchaseUpdate update) async {
    completed.add(update);
    return ackOk;
  }
}

class FakeVerifier implements PlusPurchaseVerifier {
  FakeVerifier([this.verdict = PlusVerdict.valid]);
  PlusVerdict verdict;
  int calls = 0;
  bool configured = true;

  /// Replaces [verdict] to throw or hang.
  Future<PlusVerdict> Function()? next;
  @override
  bool get isConfigured => configured;
  @override
  Future<PlusVerdict> verify(PlusPurchaseProof proof) async {
    calls++;
    if (!configured) return PlusVerdict.unavailable;
    final custom = next;
    return custom != null ? custom() : verdict;
  }
}

class RecordingAds extends NoOpAdService {
  final adFree = <bool>[];
  bool busy = false;
  int claims = 0, releases = 0;
  @override
  void setAdFree(bool value) => adFree.add(value);
  @override
  bool claimFullscreen() {
    if (busy) return false;
    claims++;
    return true;
  }

  @override
  void releaseFullscreen() => releases++;
}

class FakePlusAccess extends ChangeNotifier implements PlusAccess {
  bool _active = false;
  @override
  bool get isActive => _active;
  set active(bool value) {
    _active = value;
    notifyListeners();
  }
}

Future<void> settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakePlusStore store;
  late FakeVerifier verifier;
  late RecordingAds ads;

  late DateTime clock;
  PlusEntitlementController make({
    bool requireClaims = false,
    Duration verifyTimeout = const Duration(seconds: 20),
  }) => PlusEntitlementController(
    store: store,
    verifier: verifier,
    productId: _id,
    ads: ads,
    requireSupportedSaleClaims: requireClaims,
    verifyTimeout: verifyTimeout,
    nowUtc: () => clock,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    clock = DateTime.utc(2026, 10, 29, 9);
    store = FakePlusStore();
    verifier = FakeVerifier();
    ads = RecordingAds();
  });

  group('checkout gate', () {
    test('a missing verifier keeps checkout closed', () async {
      verifier.configured = false;
      final plus = make()..start();
      await settle();
      expect(plus.checkoutBlockReason, PlusBlockReason.verifierNotConfigured);
      expect(await plus.buy(), isFalse);
      expect(store.buys, 0);
    });

    test('unsupported reference price/discount blocks the sale CTA', () async {
      final plus = make(requireClaims: true)..start();
      await settle();
      expect(plus.checkoutBlockReason, PlusBlockReason.unsupportedSaleClaims);
      expect(await plus.buy(), isFalse);
      expect(store.buys, 0);
    });

    test('unavailable store or product blocks checkout', () async {
      store.product = null;
      final plus = make()..start();
      await settle();
      expect(plus.checkoutBlockReason, PlusBlockReason.productUnavailable);
      store.available = false;
      final other = make()..start();
      await settle();
      expect(other.checkoutBlockReason, PlusBlockReason.storeUnavailable);
    });

    test('a busy ad / consent form blocks checkout', () async {
      ads.busy = true;
      final plus = make()..start();
      await settle();
      expect(await plus.buy(), isFalse);
      expect(plus.lastBlock, PlusBlockReason.fullscreenBusy);
      expect(store.buys, 0);
    });
  });

  group('purchase lifecycle', () {
    test('launching checkout grants nothing; pending grants nothing', () async {
      final plus = make()..start();
      await settle();
      expect(await plus.buy(), isTrue);
      expect(plus.isActive, isFalse);
      expect(plus.checkout, PlusCheckoutState.purchasing);
      expect(ads.claims, 1);
      store.emit(update(PlusPurchaseStatus.pending, needsCompletion: false));
      await settle();
      expect(plus.isActive, isFalse);
      expect(plus.checkout, PlusCheckoutState.pending);
      expect(ads.releases, 1, reason: 'pending must not hold the ad guard');
      expect(store.completed, isEmpty);
      expect(verifier.calls, 0);
    });

    test(
      'only a verified purchase grants, persists and acknowledges',
      () async {
        final plus = make()..start();
        await settle();
        await plus.buy();
        store.emit(update(PlusPurchaseStatus.purchased));
        await settle();
        expect(plus.isActive, isTrue);
        expect(plus.lastOutcome, PlusPurchaseOutcome.verified);
        expect(store.completed, hasLength(1));
        expect(ads.adFree, [true]);
        final saved = jsonDecode(
          (await SharedPreferences.getInstance()).getString(
            PlusEntitlementController.storageKey,
          )!,
        );
        expect(saved['active'], isTrue);
      },
    );

    test('ordinary duplicate callbacks deliver once and verify once', () async {
      final plus = make()..start();
      await settle();
      store.emit(update(PlusPurchaseStatus.purchased));
      store.emit(update(PlusPurchaseStatus.purchased));
      store.emit(update(PlusPurchaseStatus.purchased));
      await settle();
      expect(verifier.calls, 1);
      expect(ads.adFree, [true]);
      expect(plus.isActive, isTrue);
      // A restored copy is revalidated, but delivers nothing again.
      store.emit(update(PlusPurchaseStatus.restored));
      await settle();
      expect(verifier.calls, 2);
      expect(ads.adFree, [true]);
    });

    for (final verdict in [
      PlusVerdict.invalid,
      PlusVerdict.unavailable,
      PlusVerdict.revoked,
    ]) {
      test('$verdict never grants or acknowledges', () async {
        verifier.verdict = verdict;
        final plus = make()..start();
        await settle();
        store.emit(update(PlusPurchaseStatus.purchased));
        await settle();
        expect(plus.isActive, isFalse);
        expect(store.completed, isEmpty);
      });
    }

    test('a receipt without a configured verifier never grants', () async {
      verifier.configured = false;
      final plus = make()..start();
      await settle();
      store.emit(update(PlusPurchaseStatus.purchased));
      await settle();
      expect(plus.isActive, isFalse);
      expect(plus.lastOutcome, PlusPurchaseOutcome.verificationUnavailable);
    });

    test('cancel and error grant nothing and free the ad guard', () async {
      final plus = make()..start();
      await settle();
      await plus.buy();
      store.emit(update(PlusPurchaseStatus.canceled, needsCompletion: false));
      await settle();
      expect(plus.isActive, isFalse);
      expect(plus.lastOutcome, PlusPurchaseOutcome.canceled);
      expect(plus.checkout, PlusCheckoutState.idle);
      expect(ads.releases, 1);
      await plus.buy();
      store.emit(update(PlusPurchaseStatus.error, needsCompletion: false));
      await settle();
      expect(plus.isActive, isFalse);
      expect(plus.lastOutcome, PlusPurchaseOutcome.failed);
    });

    testWidgets('a checkout that never reports frees the guard on resume', (
      tester,
    ) async {
      final plus = make();
      unawaited(plus.start());
      await tester.pump();
      await tester.pump();
      expect(await plus.buy(), isTrue);
      plus.appResumed();
      expect(ads.releases, 1);
      expect(plus.checkout, PlusCheckoutState.purchasing);
      await tester.pump(const Duration(seconds: 11));
      expect(plus.checkout, PlusCheckoutState.idle);
      expect(plus.isActive, isFalse);
      plus.dispose();
    });
  });

  group('restore and restart', () {
    test('restore with nothing owned reports nothingToRestore', () async {
      final plus = make()..start();
      await settle();
      expect(await plus.restore(), PlusRestoreResult.nothingToRestore);
      expect(plus.isActive, isFalse);
    });

    test('restore of a verified purchase grants', () async {
      final plus = make()..start();
      await settle();
      store.owned = [update(PlusPurchaseStatus.restored)];
      expect(await plus.restore(), PlusRestoreResult.restored);
      expect(plus.isActive, isTrue);
    });

    test('restore while the verifier is down grants nothing', () async {
      verifier.verdict = PlusVerdict.unavailable;
      final plus = make()..start();
      await settle();
      store.owned = [update(PlusPurchaseStatus.restored)];
      expect(await plus.restore(), PlusRestoreResult.verificationUnavailable);
      expect(plus.isActive, isFalse);
    });

    test(
      'startup recovers a purchase completed while the app was killed',
      () async {
        store.owned = [update(PlusPurchaseStatus.purchased)];
        final plus = make();
        await plus.start();
        await settle();
        expect(plus.isActive, isTrue);
        expect(plus.lastRestore, isNull, reason: 'silent reconciliation');
      },
    );

    Future<void> grantAndRestart() async {
      final first = make()..start();
      await settle();
      store.emit(update(PlusPurchaseStatus.purchased));
      await settle();
      expect(first.isActive, isTrue);
      first.dispose();
    }

    test('verified access survives an offline restart', () async {
      await grantAndRestart();
      verifier.verdict = PlusVerdict.unavailable;
      store.available = false;
      final second = make();
      await second.loadCached();
      expect(second.isActive, isTrue);
      await second.start();
      await settle();
      expect(second.isActive, isTrue);
    });

    test('a confirmed revocation removes access and restores ads', () async {
      await grantAndRestart();
      verifier.verdict = PlusVerdict.revoked;
      ads.adFree.clear();
      final second = make();
      await second.start();
      await settle();
      expect(second.isActive, isFalse);
      expect(ads.adFree, [true, false]);
      final third = make();
      await third.loadCached();
      expect(third.isActive, isFalse);
    });

    test('a corrupt record grants nothing', () async {
      SharedPreferences.setMockInitialValues({
        PlusEntitlementController.storageKey: '{"active": true}',
      });
      final plus = make();
      await plus.loadCached();
      expect(plus.isActive, isFalse);
    });
  });

  group('quota with Plus', () {
    late FakePlusAccess access;
    late SharedPreferencesReadingQuotaController quota;
    final morning = DateTime(2026, 10, 29, 8);
    setUp(() {
      access = FakePlusAccess();
      quota = SharedPreferencesReadingQuotaController(plus: access);
    });

    test('free keeps 3 credits and the 3-hour cooldown', () async {
      await quota.consumeReading(morning);
      expect(quota.maxDailyFreeReadings, 3);
      expect(quota.isAvailable(morning.add(const Duration(hours: 1))), isFalse);
      expect(quota.isAvailable(morning.add(const Duration(hours: 3))), isTrue);
    });

    test('Plus gives 6 shared credits with no cooldown, not 3 + 6', () async {
      access.active = true;
      for (var i = 0; i < 6; i++) {
        expect(quota.isAvailable(morning), isTrue);
        await quota.consumeReading(morning);
      }
      expect(quota.isAvailable(morning), isFalse);
      await expectLater(
        quota.consumeReading(morning),
        throwsA(isA<ReadingQuotaUnavailableException>()),
      );
    });

    test('upgrade keeps usage: two used leaves four', () async {
      await quota.consumeReading(morning);
      await quota.consumeReading(morning.add(const Duration(hours: 3)));
      access.active = true;
      final now = morning.add(const Duration(hours: 3, minutes: 1));
      expect(quota.dailyFreeReadingsUsed(now), 2);
      expect(quota.maxDailyFreeReadings - quota.dailyFreeReadingsUsed(now), 4);
      expect(quota.isAvailable(now), isTrue);
    });

    test('revocation and re-upgrade never refill credits', () async {
      access.active = true;
      for (var i = 0; i < 5; i++) {
        await quota.consumeReading(morning);
      }
      access.active = false;
      expect(quota.isAvailable(morning), isFalse);
      access.active = true;
      expect(quota.isAvailable(morning), isTrue);
      await quota.consumeReading(morning);
      expect(quota.isAvailable(morning), isFalse);
    });

    test(
      'midnight resets Plus credits; bonus survives and spends first',
      () async {
        access.active = true;
        await quota.earnBonusReading();
        expect(
          await quota.consumeReading(morning),
          ReadingEntitlementSource.bonus,
        );
        expect(quota.dailyFreeReadingsUsed(morning), 0);
        for (var i = 0; i < 6; i++) {
          await quota.consumeReading(morning);
        }
        expect(quota.isAvailable(morning), isFalse);
        final tomorrow = DateTime(2026, 10, 30, 0, 0, 1);
        expect(quota.isAvailable(tomorrow), isTrue);
        expect(quota.dailyFreeReadingsUsed(tomorrow), 0);
      },
    );

    test('a Plus change notifies quota listeners', () {
      var calls = 0;
      quota.addListener(() => calls++);
      access.active = true;
      expect(calls, 1);
    });
  });

  group('ad-free service', () {
    late FakeAdsBackend backend;
    late ManagedAdService service;
    setUp(() {
      backend = FakeAdsBackend();
      service = ManagedAdService(
        backend: backend,
        policy: AdPolicy(store: MemoryAdPolicyStore()),
      );
    });
    tearDown(() => service.dispose());

    test(
      'drops cached ads, ignores late loads, requests and shows none',
      () async {
        await service.initialize();
        final cached = backend.ready(AdFormat.rewarded);
        final pending = backend.requests(AdFormat.interstitial).last;
        expect(service.presentation.value.canRequestAds, isTrue);
        service.setAdFree(true);
        expect(cached.disposeCount, 1);
        expect(service.presentation.value.canRequestAds, isFalse);
        final late = FakeFullscreenAd();
        pending.loaded(late);
        expect(late.disposeCount, 1, reason: 'late success is discarded');
        final before = backend.loads.length;
        service.preloadInterstitial();
        service.preloadRewarded();
        service.setForeground(false);
        service.setForeground(true);
        expect(backend.loads.length, before);
        expect(
          await service.showRewarded(onEarnedReward: () async {}),
          AdOutcome.skipped,
        );
        var dismissed = false;
        await service.showInterstitial(onDismissed: () => dismissed = true);
        expect(dismissed, isTrue);
        expect(late.showCount, 0);
      },
    );

    test('revocation resumes ordinary preloading but shows nothing', () async {
      await service.initialize();
      service.setAdFree(true);
      final before = backend.loads.length;
      service.setAdFree(false);
      expect(backend.loads.length, before + 2);
      expect(service.presentation.value.canRequestAds, isTrue);
    });

    test('checkout guard excludes ads and consent forms', () async {
      await service.initialize();
      final ad = backend.ready(AdFormat.rewarded);
      expect(service.claimFullscreen(), isTrue);
      expect(service.claimFullscreen(), isFalse);
      expect(
        await service.showRewarded(onEarnedReward: () async {}),
        AdOutcome.skipped,
      );
      expect(ad.showCount, 0);
      service.releaseFullscreen();
      expect(service.presentation.value.fullscreenBusy, isFalse);
    });
  });

  group('demo billing', () {
    test('only a debug build with the explicit flag enables it', () {
      expect(plusDemoBillingEnabled(debug: false, requested: true), isFalse);
      expect(plusDemoBillingEnabled(debug: true, requested: false), isFalse);
      expect(plusDemoBillingEnabled(debug: true, requested: true), isTrue);
    });

    PlusEntitlementController demo() => PlusEntitlementController(
      store: DemoPlusStore(delay: Duration.zero),
      verifier: const DemoPlusVerifier(),
      productId: PlusBillingConfig.defaultProductId,
      ads: ads,
      requireSupportedSaleClaims: false,
      acceptDemoProofs: true,
    );

    test('Buy grants demo Plus through the normal verified path', () async {
      final plus = demo()..start();
      await settle();
      expect(plus.product?.isPreview, isTrue);
      expect(plus.checkoutBlockReason, isNull);
      expect(await plus.buy(), isTrue);
      expect(plus.isActive, isFalse, reason: 'launching is not a purchase');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await settle();
      expect(plus.isActive, isTrue);
      expect(ads.adFree, [true]);
    });

    test('Restore finds an earlier demo purchase on this install', () async {
      final first = demo()..start();
      await settle();
      await first.buy();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await settle();
      first.dispose();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(PlusEntitlementController.storageKey);
      final second = demo();
      await second.loadCached();
      expect(second.isActive, isFalse);
      second.start();
      await settle();
      expect(second.isActive, isTrue);
    });

    test('the demo verifier rejects real store receipts', () async {
      expect(
        await const DemoPlusVerifier().verify(proof('real-token')),
        PlusVerdict.invalid,
      );
    });

    test('a demo entitlement never carries into a store build', () async {
      final plus = demo()..start();
      await settle();
      await plus.buy();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await settle();
      expect(plus.isActive, isTrue);
      final storeBuild = make();
      await storeBuild.loadCached();
      expect(storeBuild.isActive, isFalse);
    });
  });

  group('lifecycle fixes', () {
    // The real Android adapter output for a launch Play answered without a
    // purchase list (in_app_purchase_android 0.5.5).
    PlusPurchaseUpdate androidAnonymous(PurchaseStatus status, String code) =>
        InAppPurchasePlusStore.map(
          PurchaseDetails(
              purchaseID: '',
              productID: '',
              status: status,
              transactionDate: null,
              verificationData: PurchaseVerificationData(
                localVerificationData: '',
                serverVerificationData: '',
                source: 'google_play',
              ),
            )
            ..error = IAPError(
              source: 'google_play',
              code: 'purchase_error',
              message: code,
              details: 'debug text that must not leak',
            ),
        );

    Future<PlusEntitlementController> purchasing() async {
      final plus = make()..start();
      await settle();
      expect(await plus.buy(), isTrue);
      expect(plus.checkout, PlusCheckoutState.purchasing);
      return plus;
    }

    test('1: a throwing verifier frees checkout and grants nothing', () async {
      final plus = await purchasing();
      verifier.next = () => throw StateError('verifier down');
      store.emit(update(PlusPurchaseStatus.purchased));
      await settle();
      expect(plus.checkout, PlusCheckoutState.idle);
      expect(plus.lastOutcome, PlusPurchaseOutcome.verificationUnavailable);
      expect(plus.isActive, isFalse);
      expect(store.completed, isEmpty, reason: 'nothing acknowledged');
      expect(ads.releases, 1);
      expect(plus.checkoutBlockReason, isNull, reason: 'Buy works again');
      // 3: a later redelivery succeeds once the verifier is back.
      verifier.next = null;
      store.emit(update(PlusPurchaseStatus.purchased));
      await settle();
      expect(plus.isActive, isTrue);
      expect(store.completed, hasLength(1));
    });

    testWidgets('2: a hung verifier times out; its late answer is dropped', (
      tester,
    ) async {
      final hung = Completer<PlusVerdict>();
      verifier.next = () => hung.future;
      final plus = make(verifyTimeout: const Duration(seconds: 5));
      unawaited(plus.start());
      await tester.pump();
      await tester.pump();
      await plus.buy();
      store.emit(update(PlusPurchaseStatus.purchased));
      await tester.pump();
      expect(plus.checkout, PlusCheckoutState.verifying);
      await tester.pump(const Duration(seconds: 6));
      expect(plus.checkout, PlusCheckoutState.idle);
      expect(plus.lastOutcome, PlusPurchaseOutcome.verificationUnavailable);
      hung.complete(PlusVerdict.valid);
      await tester.pump();
      expect(plus.isActive, isFalse, reason: 'stale result never applied');
      // The queue is not blocked: a later update is processed.
      verifier.next = null;
      store.emit(update(PlusPurchaseStatus.purchased));
      await tester.pump();
      await tester.pump();
      expect(plus.isActive, isTrue);
      plus.dispose();
    });

    Future<void> grant() async {
      final plus = make()..start();
      await settle();
      store.emit(update(PlusPurchaseStatus.purchased));
      await settle();
      expect(plus.isActive, isTrue);
      plus.dispose();
    }

    test('4: cached access survives a failing verifier at startup', () async {
      await grant();
      verifier.next = () => throw StateError('down');
      store.owned = [
        update(PlusPurchaseStatus.restored, needsCompletion: false),
      ];
      final again = make();
      await again.start();
      await settle();
      expect(again.isActive, isTrue);
    });

    test('5: Android already-owned with an empty productID recovers through '
        'the owned query', () async {
      final mapped = androidAnonymous(
        PurchaseStatus.error,
        'BillingResponse.itemAlreadyOwned',
      );
      expect(mapped.productId, isEmpty);
      expect(mapped.error, PlusStoreError.alreadyOwned);
      expect(mapped.proof, isNull);
      final plus = await purchasing();
      final queries = store.restores;
      store.owned = [update(PlusPurchaseStatus.restored)];
      store.emit(mapped);
      await settle();
      expect(store.restores, queries + 1);
      expect(plus.isActive, isTrue);
      expect(plus.checkout, PlusCheckoutState.idle);
      expect(ads.releases, 1);
    });

    test(
      '5b: an anonymous callback with no checkout of ours is ignored',
      () async {
        final plus = make()..start();
        await settle();
        final queries = store.restores;
        store.owned = [update(PlusPurchaseStatus.restored)];
        store.emit(
          androidAnonymous(
            PurchaseStatus.error,
            'BillingResponse.itemAlreadyOwned',
          ),
        );
        store.emit(androidAnonymous(PurchaseStatus.purchased, 'x'));
        await settle();
        expect(store.restores, queries);
        expect(plus.isActive, isFalse);
      },
    );

    test('6: a realistic cancellation settles checkout at once', () async {
      final mapped = androidAnonymous(
        PurchaseStatus.canceled,
        'BillingResponse.userCanceled',
      );
      expect(mapped.status, PlusPurchaseStatus.canceled);
      expect(mapped.error, PlusStoreError.other);
      final plus = await purchasing();
      store.emit(mapped);
      await settle();
      expect(plus.checkout, PlusCheckoutState.idle);
      expect(plus.lastOutcome, PlusPurchaseOutcome.canceled);
      expect(plus.isActive, isFalse);
      expect(ads.releases, 1);
      final error = androidAnonymous(
        PurchaseStatus.error,
        'BillingResponse.serviceUnavailable',
      );
      await plus.buy();
      store.emit(error);
      await settle();
      expect(plus.checkout, PlusCheckoutState.idle);
      expect(plus.lastOutcome, PlusPurchaseOutcome.failed);
      expect(plus.isActive, isFalse);
    });

    test('Android acknowledgement result is read, not assumed', () {
      expect(
        InAppPurchasePlusStore.acknowledged(
          const BillingResultWrapper(responseCode: BillingResponse.ok),
        ),
        isTrue,
      );
      expect(
        InAppPurchasePlusStore.acknowledged(
          const BillingResultWrapper(responseCode: BillingResponse.error),
        ),
        isFalse,
      );
      expect(
        InAppPurchasePlusStore.acknowledged(
          const BillingResultWrapper(
            responseCode: BillingResponse.serviceDisconnected,
          ),
        ),
        isFalse,
      );
    });

    test('7: a failed acknowledgement is retried by the next start', () async {
      store.ackOk = false;
      final first = make()..start();
      await settle();
      store.emit(update(PlusPurchaseStatus.purchased));
      await settle();
      expect(first.isActive, isTrue);
      expect(first.acknowledgementPending, isTrue);
      first.dispose();
      store.ackOk = true;
      // Play lists it again as unacknowledged.
      store.owned = [update(PlusPurchaseStatus.restored)];
      ads.adFree.clear();
      final second = make();
      await second.start();
      await settle();
      expect(second.isActive, isTrue);
      expect(second.acknowledgementPending, isFalse);
      expect(store.completed, hasLength(2));
      expect(ads.adFree, [true], reason: 'the cached grant only');
    });

    test(
      '8: repeated failures retry on resume, spaced, without regrants',
      () async {
        store.ackOk = false;
        final plus = make()..start();
        await settle();
        store.emit(update(PlusPurchaseStatus.purchased));
        await settle();
        store.owned = [update(PlusPurchaseStatus.restored)];
        final queries = store.restores;
        plus.appResumed();
        await settle();
        expect(store.restores, queries, reason: 'inside the retry interval');
        clock = clock.add(const Duration(minutes: 2));
        plus.appResumed();
        await settle();
        expect(store.restores, queries + 1);
        expect(plus.acknowledgementPending, isTrue);
        store.ackOk = true;
        plus.appResumed();
        await settle();
        expect(store.restores, queries + 1, reason: 'no retry storm');
        clock = clock.add(const Duration(minutes: 2));
        plus.appResumed();
        await settle();
        expect(plus.acknowledgementPending, isFalse);
        expect(ads.adFree, [true]);
        expect(plus.isActive, isTrue);
      },
    );

    test('9: explicit Restore revalidates a granted token and applies a '
        'confirmed revocation', () async {
      final plus = make()..start();
      await settle();
      store.emit(update(PlusPurchaseStatus.purchased));
      await settle();
      expect(plus.isActive, isTrue);
      verifier.verdict = PlusVerdict.revoked;
      store.owned = [
        update(PlusPurchaseStatus.restored, needsCompletion: false),
      ];
      expect(await plus.restore(), PlusRestoreResult.nothingToRestore);
      expect(plus.isActive, isFalse);
      expect(ads.adFree, [true, false]);
    });

    test(
      '9b: Restore with the verifier down or an empty list keeps access',
      () async {
        final plus = make()..start();
        await settle();
        store.emit(update(PlusPurchaseStatus.purchased));
        await settle();
        verifier.verdict = PlusVerdict.unavailable;
        store.owned = [
          update(PlusPurchaseStatus.restored, needsCompletion: false),
        ];
        expect(await plus.restore(), PlusRestoreResult.restored);
        expect(plus.isActive, isTrue);
        store.owned = [];
        expect(await plus.restore(), PlusRestoreResult.restored);
        store.restoreThrows = true;
        expect(await plus.restore(), PlusRestoreResult.failed);
        expect(plus.isActive, isTrue);
      },
    );

    test('11: an unavailable store recovers in the same session', () async {
      store.available = false;
      final plus = make()..start();
      await settle();
      expect(plus.checkoutBlockReason, PlusBlockReason.storeUnavailable);
      store.available = true;
      // Resume inside the interval does not hammer the store.
      final checks = store.availabilityChecks;
      plus.appResumed();
      await settle();
      expect(store.availabilityChecks, checks);
      clock = clock.add(const Duration(minutes: 2));
      plus.appResumed();
      await settle();
      expect(plus.checkoutBlockReason, isNull);
      expect(plus.product?.price, '119.000 ₫');
    });

    test('12: a failed product query recovers on the next Buy tap', () async {
      store.queryThrows = true;
      final plus = make()..start();
      await settle();
      expect(plus.checkoutBlockReason, PlusBlockReason.productUnavailable);
      store.queryThrows = false;
      expect(await plus.buy(), isTrue);
      expect(store.buys, 1);
      expect(plus.isActive, isFalse, reason: 'launching is not a purchase');
    });

    test(
      '12b: recovery never bypasses the verifier or sale-claim gates',
      () async {
        store.available = false;
        final plus = make(requireClaims: true)..start();
        await settle();
        store.available = true;
        expect(await plus.buy(), isFalse);
        expect(plus.lastBlock, PlusBlockReason.unsupportedSaleClaims);
        verifier.configured = false;
        final other = make()..start();
        await settle();
        expect(await other.buy(), isFalse);
        expect(other.lastBlock, PlusBlockReason.verifierNotConfigured);
        expect(store.buys, 0);
      },
    );

    test('13: overlapping start, Restore and resume share one query', () async {
      final plus = make();
      final starting = plus.start();
      final restoring = plus.restore();
      plus.appResumed();
      await starting;
      await restoring;
      await settle();
      expect(store.availabilityChecks, 1);
      expect(store.restores, 1);
    });

    test(
      '14: late work after dispose mutates neither entitlement nor ads',
      () async {
        final hung = Completer<PlusVerdict>();
        verifier.next = () => hung.future;
        final plus = make()..start();
        await settle();
        store.emit(update(PlusPurchaseStatus.purchased));
        await settle();
        plus.dispose();
        hung.complete(PlusVerdict.valid);
        await settle();
        expect(ads.adFree, isEmpty);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(PlusEntitlementController.storageKey), isNull);
        expect(store.completed, isEmpty);
      },
    );
  });
  group('recovery after restart and pending payments', () {
    // What Android's restore really emits: every listed purchase relabelled
    // "restored", whatever its purchase state (in_app_purchase_android 0.5.5).
    PlusPurchaseUpdate androidListed(PurchaseStateWrapper state) =>
        InAppPurchasePlusStore.map(
          GooglePlayPurchaseDetails.fromPurchase(
            PurchaseWrapper(
              orderId: 'order-tok',
              packageName: 'app',
              purchaseTime: 0,
              purchaseToken: 'tok',
              signature: 'sig',
              products: const [_id],
              isAutoRenewing: false,
              originalJson: '{}',
              isAcknowledged: false,
              purchaseState: state,
            ),
          ).single..status = PurchaseStatus.restored,
        );

    void later() => clock = clock.add(const Duration(minutes: 2));

    /// Cached, verified Plus whose acknowledgement never reached the store.
    Future<void> unacknowledgedOwner() async {
      store.ackOk = false;
      final first = make()..start();
      await settle();
      store.emit(update(PlusPurchaseStatus.purchased));
      await settle();
      expect(first.isActive, isTrue);
      expect(first.acknowledgementPending, isTrue);
      first.dispose();
      store.ackOk = true;
      store.owned = [androidListed(PurchaseStateWrapper.purchased)];
      ads.adFree.clear();
    }

    Future<PlusEntitlementController> pendingCheckout() async {
      final plus = make()..start();
      await settle();
      expect(await plus.buy(), isTrue);
      store.emit(update(PlusPurchaseStatus.pending));
      await settle();
      plus.appResumed(); // the store sheet closes
      await settle();
      expect(plus.checkout, PlusCheckoutState.pending);
      expect(plus.isActive, isFalse);
      return plus;
    }

    test('R1: failed ack, restart, failed startup query, then an eligible '
        'resume acknowledges', () async {
      await unacknowledgedOwner();
      store.restoreThrows = true;
      final plus = make();
      await plus.start();
      await settle();
      expect(plus.isActive, isTrue, reason: 'cached access is kept');
      expect(store.completed, hasLength(1), reason: 'only the failed attempt');
      store.restoreThrows = false;
      final queries = store.restores;
      plus.appResumed();
      await settle();
      expect(store.restores, queries, reason: 'inside the retry interval');
      later();
      plus.appResumed();
      await settle();
      expect(store.restores, queries + 1);
      expect(store.completed, hasLength(2));
      expect(plus.acknowledgementPending, isFalse);
      expect(plus.isActive, isTrue);
      expect(ads.adFree, [true], reason: 'the cached grant only');
    });

    test('R2: cached Plus with the store down at start reconciles once '
        'discovery succeeds', () async {
      await unacknowledgedOwner();
      store.available = false;
      final plus = make();
      await plus.start();
      await settle();
      expect(plus.isActive, isTrue);
      final queries = store.restores;
      expect(store.completed, hasLength(1));
      store.available = true;
      later();
      plus.appResumed();
      await settle();
      expect(store.restores, queries + 1);
      expect(store.completed, hasLength(2));
      expect(plus.acknowledgementPending, isFalse);
      expect(ads.adFree, [true]);
    });

    test(
      'R3: repeated query failures retry spaced, never regranting',
      () async {
        await unacknowledgedOwner();
        store.restoreThrows = true;
        final plus = make();
        await plus.start();
        await settle();
        final queries = store.restores;
        for (var i = 1; i <= 3; i++) {
          plus.appResumed();
          plus.appResumed();
          await settle();
          expect(store.restores, queries + i - 1, reason: 'not yet due');
          later();
          plus.appResumed();
          await settle();
          expect(store.restores, queries + i);
        }
        expect(plus.isActive, isTrue);
        expect(ads.adFree, [true]);
        store.restoreThrows = false;
        later();
        plus.appResumed();
        await settle();
        expect(store.completed, hasLength(2));
        expect(plus.acknowledgementPending, isFalse);
        expect(ads.adFree, [true], reason: 'no duplicate grant');
      },
    );

    test('R4: a successful recovery leaves no retry work behind', () async {
      await unacknowledgedOwner();
      store.restoreThrows = true;
      final plus = make();
      await plus.start();
      await settle();
      store.restoreThrows = false;
      later();
      plus.appResumed();
      await settle();
      final queries = store.restores;
      for (var i = 0; i < 3; i++) {
        later();
        plus.appResumed();
        await settle();
      }
      expect(store.restores, queries, reason: 'nothing left to recover');
      expect(store.completed, hasLength(2));
    });

    test('R5: a pending payment completed while away is granted, '
        'acknowledged and settles checkout on resume', () async {
      final plus = await pendingCheckout();
      final queries = store.restores;
      // Completed in the store; no stream callback reaches this controller.
      store.owned = [androidListed(PurchaseStateWrapper.purchased)];
      later();
      plus.appResumed();
      await settle();
      expect(store.restores, queries + 1);
      expect(plus.isActive, isTrue);
      expect(plus.checkout, PlusCheckoutState.idle);
      expect(plus.lastOutcome, PlusPurchaseOutcome.verified);
      expect(store.completed, hasLength(1));
      expect(ads.adFree, [true]);
      expect(store.buys, 1, reason: 'no purchase is launched again');
      expect(ads.claims, ads.releases, reason: 'no guard left held');
      later();
      plus.appResumed();
      await settle();
      expect(store.restores, queries + 1, reason: 'settled; no more queries');
    });

    test(
      'R6: a payment still pending grants and acknowledges nothing',
      () async {
        expect(
          androidListed(PurchaseStateWrapper.pending).status,
          PlusPurchaseStatus.pending,
        );
        final plus = await pendingCheckout();
        store.owned = [androidListed(PurchaseStateWrapper.pending)];
        later();
        plus.appResumed();
        await settle();
        expect(plus.isActive, isFalse);
        expect(plus.checkout, PlusCheckoutState.pending);
        expect(store.completed, isEmpty);
        expect(verifier.calls, 0);
        // Still recoverable on the next eligible resume.
        final queries = store.restores;
        store.owned = [androidListed(PurchaseStateWrapper.purchased)];
        later();
        plus.appResumed();
        await settle();
        expect(store.restores, queries + 1);
        expect(plus.isActive, isTrue);
        expect(plus.checkout, PlusCheckoutState.idle);
      },
    );

    test(
      'R6b: a pending payment found at start is retried on resume',
      () async {
        store.owned = [androidListed(PurchaseStateWrapper.pending)];
        final plus = make();
        await plus.start();
        await settle();
        expect(plus.isActive, isFalse);
        expect(store.completed, isEmpty);
        store.owned = [androidListed(PurchaseStateWrapper.purchased)];
        later();
        plus.appResumed();
        await settle();
        expect(plus.isActive, isTrue);
        expect(store.completed, hasLength(1));
      },
    );

    test('R7: an empty or failed query while pending neither cancels nor '
        'grants', () async {
      final plus = await pendingCheckout();
      store.owned = [];
      later();
      plus.appResumed();
      await settle();
      expect(plus.checkout, PlusCheckoutState.pending);
      expect(plus.lastOutcome, PlusPurchaseOutcome.pending);
      store.restoreThrows = true;
      later();
      plus.appResumed();
      await settle();
      expect(plus.checkout, PlusCheckoutState.pending);
      expect(plus.isActive, isFalse);
      expect(store.completed, isEmpty);
      expect(ads.adFree, isEmpty);
    });

    test('R8: verifier down during pending recovery, then a later retry '
        'succeeds', () async {
      final plus = await pendingCheckout();
      store.owned = [androidListed(PurchaseStateWrapper.purchased)];
      verifier.verdict = PlusVerdict.unavailable;
      later();
      plus.appResumed();
      await settle();
      expect(plus.isActive, isFalse);
      expect(plus.checkout, PlusCheckoutState.pending);
      expect(store.completed, isEmpty, reason: 'unverified: not acknowledged');
      verifier.verdict = PlusVerdict.valid;
      later();
      plus.appResumed();
      await settle();
      expect(plus.isActive, isTrue);
      expect(plus.checkout, PlusCheckoutState.idle);
      expect(store.completed, hasLength(1));
    });

    test('R8b: an unverified owned purchase found at start is retried on '
        'resume, not only by Restore', () async {
      store.owned = [androidListed(PurchaseStateWrapper.purchased)];
      verifier.verdict = PlusVerdict.unavailable;
      final plus = make();
      await plus.start();
      await settle();
      expect(plus.isActive, isFalse);
      verifier.verdict = PlusVerdict.valid;
      later();
      plus.appResumed();
      await settle();
      expect(plus.isActive, isTrue);
      expect(store.completed, hasLength(1));
    });

    test('R9: overlapping resumes share one recovery query', () async {
      final plus = await pendingCheckout();
      store.owned = [androidListed(PurchaseStateWrapper.purchased)];
      final gate = Completer<PlusVerdict>();
      verifier.next = () => gate.future;
      final queries = store.restores;
      later();
      plus.appResumed();
      await settle();
      later();
      plus.appResumed();
      plus.appResumed();
      await settle();
      expect(store.restores, queries + 1);
      gate.complete(PlusVerdict.valid);
      await settle();
      expect(verifier.calls, 1);
      expect(plus.isActive, isTrue);
      expect(ads.adFree, [true]);
    });

    test('R10: recovery finishing after dispose changes nothing', () async {
      final plus = await pendingCheckout();
      store.owned = [androidListed(PurchaseStateWrapper.purchased)];
      final gate = Completer<PlusVerdict>();
      verifier.next = () => gate.future;
      later();
      plus.appResumed();
      await settle();
      plus.dispose();
      gate.complete(PlusVerdict.valid);
      await settle();
      expect(plus.isActive, isFalse);
      expect(ads.adFree, isEmpty);
      expect(store.completed, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(PlusEntitlementController.storageKey), isNull);
    });
  });
}
