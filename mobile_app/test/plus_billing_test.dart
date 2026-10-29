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
  String? errorCode,
}) => PlusPurchaseUpdate(
  productId: _id,
  status: status,
  proof:
      status == PlusPurchaseStatus.purchased ||
          status == PlusPurchaseStatus.restored
      ? proof(token)
      : null,
  needsCompletion: needsCompletion,
  errorCode: errorCode,
);

class FakePlusStore implements PlusStore {
  final controller = StreamController<List<PlusPurchaseUpdate>>.broadcast();
  bool available = true;
  bool launches = true;
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
  Future<bool> isAvailable() async => available;
  @override
  Future<PlusProduct?> queryProduct(String productId) async => product;
  @override
  Future<bool> buy(PlusProduct product) async {
    buys++;
    return launches;
  }

  @override
  Future<void> restore() async {
    restores++;
    if (owned.isNotEmpty) controller.add(List.of(owned));
  }

  @override
  Future<void> complete(PlusPurchaseUpdate update) async =>
      completed.add(update);
}

class FakeVerifier implements PlusPurchaseVerifier {
  FakeVerifier([this.verdict = PlusVerdict.valid]);
  PlusVerdict verdict;
  int calls = 0;
  bool configured = true;
  @override
  bool get isConfigured => configured;
  @override
  Future<PlusVerdict> verify(PlusPurchaseProof proof) async {
    calls++;
    return configured ? verdict : PlusVerdict.unavailable;
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

  PlusEntitlementController make({bool requireClaims = false}) =>
      PlusEntitlementController(
        store: store,
        verifier: verifier,
        productId: _id,
        ads: ads,
        requireSupportedSaleClaims: requireClaims,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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

    test('duplicate callbacks verify and grant once', () async {
      var notifications = 0;
      final plus = make()..start();
      await settle();
      plus.addListener(() => notifications++);
      store.emit(update(PlusPurchaseStatus.purchased));
      store.emit(update(PlusPurchaseStatus.purchased));
      store.emit(update(PlusPurchaseStatus.restored));
      await settle();
      expect(verifier.calls, 1);
      expect(ads.adFree, [true]);
      expect(plus.isActive, isTrue);
      final activations = notifications;
      store.emit(update(PlusPurchaseStatus.purchased));
      await settle();
      expect(verifier.calls, 1);
      expect(notifications - activations, lessThanOrEqualTo(1));
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

    test('already owned re-queries ownership and verifies it', () async {
      final plus = make()..start();
      await settle();
      store.owned = [update(PlusPurchaseStatus.restored)];
      store.emit(
        update(
          PlusPurchaseStatus.error,
          errorCode: 'BillingResponse.itemAlreadyOwned',
        ),
      );
      await settle();
      expect(plus.isActive, isTrue);
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
}
