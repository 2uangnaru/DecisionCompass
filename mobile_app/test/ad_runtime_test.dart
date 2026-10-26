import 'dart:async';

import 'package:decision_compass/analytics/analytics_event.dart';
import 'package:decision_compass/services/ad_policy.dart';
import 'package:decision_compass/services/ad_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ads_test_fakes.dart';
import 'analytics/analytics_flow_test.dart' show RecordingAnalytics;

/// Stands in for the plugin's native interstitial so the PRODUCTION wrapper,
/// not a test fake, is what the coordinator deduplicates.
class _NativeInterstitial extends Fake implements InterstitialAd {
  int showCount = 0, disposeCount = 0;
  @override
  FullScreenContentCallback<InterstitialAd>? fullScreenContentCallback;
  @override
  OnPaidEventCallback? onPaidEvent;
  @override
  Future<void> show() async => showCount++;
  @override
  Future<void> dispose() async => disposeCount++;
  void dismiss() =>
      fullScreenContentCallback!.onAdDismissedFullScreenContent!(this);
}

void main() {
  late FakeAdsBackend backend;
  late MemoryAdPolicyStore store;
  late ManagedAdService service;
  late DateTime clock;
  setUp(() {
    clock = DateTime.utc(2026, 10, 26, 12);
    backend = FakeAdsBackend();
    store = MemoryAdPolicyStore();
    service = ManagedAdService(
      backend: backend,
      policy: AdPolicy(store: store),
      nowUtc: () => clock,
      nowLocal: () => clock,
    );
  });
  tearDown(() => service.dispose());
  Future<void> init({bool viewed = true}) async {
    await service.initialize();
    if (viewed) await service.markReadingViewed(clock);
  }

  Future<void> advance(WidgetTester tester, Duration by) async {
    clock = clock.add(by);
    await tester.pump(by);
  }

  Future<void> inter([
    InterstitialPlacement placement = InterstitialPlacement.afterAnalysis,
  ]) => service.showInterstitial(onDismissed: () {}, placement: placement);

  // Dispose app-owned timers before widget-test invariants, not in tearDown.
  void adTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      try {
        await body(tester);
      } finally {
        service.dispose();
        await tester.pump();
      }
    });
  }

  adTest('consent denial makes zero load requests; initialization is once', (
    tester,
  ) async {
    backend.consent = false;
    await Future.wait([init(), service.initialize()]);
    service.preloadInterstitial();
    service.preloadRewarded();
    expect(backend.updateCount, 1);
    expect(backend.initializeCount, 0);
    expect(backend.loads, isEmpty);
    var grant = 0;
    expect(
      await service.showRewarded(
        onEarnedReward: () async {
          grant++;
        },
      ),
      AdOutcome.skipped,
    );
    expect(grant, 0);
  });
  adTest('preload deduplicates loading and ready ads for both formats', (
    tester,
  ) async {
    await init();
    for (var i = 0; i < 10; i++) {
      service.preloadInterstitial();
      service.preloadRewarded();
    }
    expect(backend.loads.length, 2);
    backend.ready(AdFormat.interstitial);
    backend.ready(AdFormat.rewarded);
    service.preloadInterstitial();
    service.preloadRewarded();
    expect(backend.loads.length, 2);
    expect(service.isInterstitialLoaded, true);
    expect(service.isRewardedLoaded, true);
  });
  adTest(
    'unviewed first day never shows even from History; no queued catch-up',
    (tester) async {
      await init(viewed: false);
      final ad = backend.ready(AdFormat.interstitial);
      await inter(InterstitialPlacement.history);
      expect(ad.showCount, 0);
      await service.markReadingViewed(clock);
      await advance(tester, const Duration(seconds: 31));
      expect(ad.showCount, 0);
      final shown = inter(InterstitialPlacement.history);
      await tester.pump();
      expect(ad.showCount, 1);
      ad.close();
      await shown;
    },
  );
  adTest('missing ad skips immediately; later loaded ad never auto shows', (
    tester,
  ) async {
    await init();
    var continuations = 0;
    await service.showInterstitial(onDismissed: () => continuations++);
    final ad = backend.ready(AdFormat.interstitial);
    await advance(tester, const Duration(seconds: 31));
    expect(continuations, 1);
    expect(ad.showCount, 0);
  });
  adTest(
    'no 8-second show watchdog; only native close continues, exactly once',
    (tester) async {
      await init();
      final ad = backend.ready(AdFormat.interstitial);
      var continued = 0;
      final shown = service.showInterstitial(onDismissed: () => continued++);
      await advance(tester, const Duration(seconds: 60));
      expect(continued, 0);
      expect(ad.disposeCount, 0);
      ad.close();
      ad.close();
      ad.fail();
      await shown;
      expect(continued, 1);
      expect(ad.disposeCount, 1);
      expect(backend.requests(AdFormat.interstitial), hasLength(2));
    },
  );
  adTest('global lock blocks concurrent interstitial AND rewarded', (
    tester,
  ) async {
    await init();
    final ad = backend.ready(AdFormat.interstitial);
    final reward = backend.ready(AdFormat.rewarded);
    final shown = inter();
    await tester.pump();
    await inter(InterstitialPlacement.history);
    expect(
      await service.showRewarded(onEarnedReward: () async {}),
      AdOutcome.skipped,
    );
    expect(ad.showCount, 1);
    expect(reward.showCount, 0);
    ad.close();
    await shown;
  });
  adTest('shared 30-second gap starts at DISMISSAL, boundary inclusive', (
    tester,
  ) async {
    await init();
    final first = backend.ready(AdFormat.interstitial);
    final showing = inter();
    await tester.pump();
    await advance(tester, const Duration(seconds: 40));
    first.close();
    await showing;
    final next = backend.ready(AdFormat.interstitial);
    await advance(tester, const Duration(milliseconds: 29999));
    await inter(InterstitialPlacement.history);
    expect(next.showCount, 0);
    await advance(tester, const Duration(milliseconds: 1));
    final showing2 = inter(InterstitialPlacement.history);
    await tester.pump();
    expect(next.showCount, 1);
    next.close();
    await showing2;
  });
  adTest(
    'gap survives service restart and midnight; first day resets separately',
    (tester) async {
      clock = DateTime.utc(2026, 10, 26, 23, 59, 50);
      await init();
      final ad = backend.ready(AdFormat.interstitial);
      final shown = inter();
      await tester.pump();
      ad.close();
      await shown;
      service.dispose();
      clock = clock.add(const Duration(seconds: 15));
      service = ManagedAdService(
        backend: backend,
        policy: AdPolicy(store: store),
        nowUtc: () => clock,
        nowLocal: () => clock,
      );
      await service.initialize();
      final next = backend.ready(AdFormat.interstitial);
      await inter();
      expect(next.showCount, 0);
      await service.markReadingViewed(clock);
      await inter();
      expect(next.showCount, 0);
      await advance(tester, const Duration(seconds: 15));
      final shown2 = inter();
      await tester.pump();
      expect(next.showCount, 1);
      next.close();
      await shown2;
    },
  );
  adTest(
    'no reward-to-interstitial gap; reward persists on SDK callback exactly once',
    (tester) async {
      await init();
      final rewarded = backend.ready(AdFormat.rewarded);
      final ad = backend.ready(AdFormat.interstitial);
      var grants = 0;
      final saving = Completer<void>();
      final showing = service.showRewarded(
        onEarnedReward: () async {
          grants++;
          await saving.future;
        },
      );
      await tester.pump();
      rewarded.reward();
      rewarded.reward();
      await tester.pump();
      expect(grants, 1);
      var ended = false;
      unawaited(
        showing.then((_) {
          ended = true;
        }),
      );
      rewarded.close();
      await tester.pump();
      expect(ended, false);
      saving.complete();
      expect(await showing, AdOutcome.rewarded);
      final history = inter(InterstitialPlacement.history);
      await tester.pump();
      expect(ad.showCount, 1);
      ad.close();
      await history;
    },
  );
  adTest(
    'reward close without earned callback never grants; late callback ignored',
    (tester) async {
      await init();
      final ad = backend.ready(AdFormat.rewarded);
      var grants = 0;
      final showing = service.showRewarded(
        onEarnedReward: () async {
          grants++;
        },
      );
      await tester.pump();
      ad.close();
      expect(await showing, AdOutcome.dismissed);
      ad.reward();
      await tester.pump();
      expect(grants, 0);
    },
  );
  adTest('failed reward save is its own outcome and cannot grant twice', (
    tester,
  ) async {
    await init();
    final ad = backend.ready(AdFormat.rewarded);
    var grants = 0;
    final showing = service.showRewarded(
      onEarnedReward: () async {
        grants++;
        throw StateError('disk');
      },
    );
    await tester.pump();
    ad.reward();
    await tester.pump();
    ad.reward();
    ad.close();
    expect(await showing, AdOutcome.rewardSaveFailed);
    expect(grants, 1);
  });
  adTest('reward is allowed inside interstitial gap (no extra reward gap)', (
    tester,
  ) async {
    await init();
    final ad = backend.ready(AdFormat.interstitial);
    final shown = inter();
    await tester.pump();
    ad.close();
    await shown;
    final reward = backend.ready(AdFormat.rewarded);
    final next = service.showRewarded(onEarnedReward: () async {});
    await tester.pump();
    expect(reward.showCount, 1);
    reward.close();
    await next;
  });
  for (final throws in [false, true]) {
    adTest(
      'show failure releases lock without setting dismissal gap, throws=$throws',
      (tester) async {
        await init();
        final ad = backend.ready(AdFormat.interstitial)..throwsOnShow = throws;
        final showing = inter();
        await tester.pump();
        if (!throws) ad.fail();
        await showing;
        expect(store.dismissed, null);
        expect(ad.disposeCount, 1);
        final next = backend.ready(AdFormat.interstitial);
        final showing2 = inter();
        await tester.pump();
        expect(next.showCount, 1);
        next.close();
        await showing2;
      },
    );
  }
  adTest(
    '15-second LOAD timeout, 2-second retry, stale callbacks disposed/ignored',
    (tester) async {
      await init();
      final stale = backend.requests(AdFormat.interstitial).single;
      await advance(tester, const Duration(seconds: 15));
      expect(backend.requests(AdFormat.interstitial), hasLength(1));
      await advance(tester, const Duration(seconds: 2));
      expect(backend.requests(AdFormat.interstitial), hasLength(2));
      final current = backend.ready(AdFormat.interstitial);
      final old = FakeFullscreenAd();
      stale.loaded(old);
      stale.failed();
      expect(old.disposeCount, 1);
      expect(current.disposeCount, 0);
      expect(service.isInterstitialLoaded, true);
    },
  );
  adTest('backoff 2/4/8/16/32/64/64 resets on success', (tester) async {
    await init();
    for (final seconds in [2, 4, 8, 16, 32, 64, 64]) {
      final count = backend.requests(AdFormat.interstitial).length;
      backend.requests(AdFormat.interstitial).last.failed();
      await advance(tester, Duration(milliseconds: seconds * 1000 - 1));
      expect(backend.requests(AdFormat.interstitial).length, count);
      await advance(tester, const Duration(milliseconds: 1));
      expect(backend.requests(AdFormat.interstitial).length, count + 1);
    }
    final ad = backend.ready(AdFormat.interstitial);
    final showing = inter();
    await tester.pump();
    ad.close();
    await showing;
    final count = backend.requests(AdFormat.interstitial).length;
    backend.requests(AdFormat.interstitial).last.failed();
    await advance(tester, const Duration(seconds: 2));
    expect(backend.requests(AdFormat.interstitial).length, count + 1);
  });
  adTest('cache refreshes after 50 minutes, no automatic display', (
    tester,
  ) async {
    await init();
    final ad = backend.ready(AdFormat.interstitial);
    await advance(tester, const Duration(minutes: 50));
    expect(ad.disposeCount, 1);
    expect(ad.showCount, 0);
    expect(backend.requests(AdFormat.interstitial), hasLength(2));
  });
  adTest('background pauses retries/expiry, resume refreshes without display', (
    tester,
  ) async {
    await init();
    final ad = backend.ready(AdFormat.interstitial);
    backend.requests(AdFormat.rewarded).last.failed();
    service.setForeground(false);
    await advance(tester, const Duration(hours: 1));
    expect(backend.loads.length, 2);
    expect(ad.showCount, 0);
    service.setForeground(true);
    expect(ad.disposeCount, 1);
    expect(backend.requests(AdFormat.interstitial), hasLength(2));
    expect(ad.showCount, 0);
  });
  adTest('disposal cancels retries and discards late successes', (
    tester,
  ) async {
    await init();
    final request = backend.requests(AdFormat.interstitial).last;
    backend.requests(AdFormat.rewarded).last.failed();
    service.dispose();
    final ad = FakeFullscreenAd();
    request.loaded(ad);
    await advance(tester, const Duration(minutes: 2));
    expect(ad.disposeCount, 1);
    expect(backend.loads, hasLength(2));
  });
  adTest('privacy withdrawal clears both caches and blocks new loads/shows', (
    tester,
  ) async {
    await init();
    final ad = backend.ready(AdFormat.interstitial);
    final reward = backend.ready(AdFormat.rewarded);
    backend.consent = false;
    await service.showPrivacyOptions();
    expect(ad.disposeCount, 1);
    expect(reward.disposeCount, 1);
    expect(service.isInterstitialLoaded, false);
    await inter();
    expect(ad.showCount, 0);
    expect(backend.loads, hasLength(2));
  });
  adTest('no daily interstitial cap; 15 eligible actions all show', (
    tester,
  ) async {
    await init();
    backend.ready(AdFormat.rewarded);
    for (var i = 0; i < 15; i++) {
      final ad = backend.ready(AdFormat.interstitial);
      final showing = inter(
        i.isEven
            ? InterstitialPlacement.history
            : InterstitialPlacement.afterAnalysis,
      );
      await tester.pump();
      expect(ad.showCount, 1);
      ad.close();
      await showing;
      await advance(tester, const Duration(seconds: 30));
    }
  });

  adTest(
    'actual callback tracking is distinct from show requests and honors opt-out',
    (tester) async {
      final analytics = RecordingAnalytics();
      service.dispose();
      service = ManagedAdService(
        backend: backend,
        policy: AdPolicy(store: store),
        analytics: analytics,
        nowUtc: () => clock,
        nowLocal: () => clock,
      );
      await init();
      final ad = backend.ready(AdFormat.interstitial);
      final shown = inter();
      await tester.pump();
      expect(
        analytics.events.where((e) => e.name == 'app_ad_impression'),
        isEmpty,
      );
      ad.impression();
      ad.impression();
      ad.click();
      ad.paid(12345, 'USD', 'precise');
      expect(
        analytics.events.where((e) => e.name == 'app_ad_impression'),
        hasLength(1),
      );
      // Firebase's own name is left to the SDK; the app never sends it.
      expect(analytics.events.where((e) => e.name == 'ad_impression'), isEmpty);
      expect(
        analytics.events.singleWhere((e) => e.name == 'ad_paid').parameters,
        {
          'ad_format': 'interstitial',
          'placement': 'afterAnalysis',
          'value_micros': 12345.0,
          'currency': 'USD',
          'precision': 'precise',
        },
      );
      final count = analytics.events.length;
      await analytics.setEnabled(false);
      ad.close();
      await shown;
      expect(analytics.events.length, count);
      analytics.dispose();
    },
  );

  adTest(
    'duplicate load callback cannot dispose active ad; late paid callback counts once',
    (tester) async {
      final analytics = RecordingAnalytics();
      service.dispose();
      service = ManagedAdService(
        backend: backend,
        policy: AdPolicy(store: store),
        analytics: analytics,
        nowUtc: () => clock,
        nowLocal: () => clock,
      );
      await init();
      final request = backend.requests(AdFormat.interstitial).single;
      final native = Object();
      final ad = FakeFullscreenAd(native: native);
      request.loaded(ad);
      // A second wrapper of the same native ad, while it is cached...
      final cachedDuplicate = FakeFullscreenAd(native: native);
      request.loaded(cachedDuplicate);
      expect(ad.disposeCount, 0);
      expect(cachedDuplicate.disposeCount, 0);
      expect(service.isInterstitialLoaded, true);
      final shown = inter();
      await tester.pump();
      // ...and while it is on screen.
      final showingDuplicate = FakeFullscreenAd(native: native);
      request.loaded(showingDuplicate);
      expect(ad.disposeCount, 0);
      expect(showingDuplicate.disposeCount, 0);
      ad.close();
      await shown;
      ad.paid(5000, 'USD', 'precise');
      ad.paid(5000, 'USD', 'precise');
      expect(analytics.events.where((e) => e.name == 'ad_paid'), hasLength(1));
      expect(ad.disposeCount, 1);
      analytics.dispose();
    },
  );

  test('NoOp never simulates a reward', () async {
    var grants = 0;
    expect(
      await const NoOpAdService().showRewarded(
        onEarnedReward: () async {
          grants++;
        },
      ),
      AdOutcome.skipped,
    );
    expect(grants, 0);
  });
  test(
    'ad analytics restrict vocabulary and reject untrusted currency/precision',
    () {
      expect(
        () =>
            AnalyticsEvent.adLifecycle(action: 'birthDate', format: 'rewarded'),
        throwsArgumentError,
      );
      final event = AnalyticsEvent.adLifecycle(
        action: 'paid',
        format: 'rewarded',
        placement: 'reading',
        value: double.nan,
        currency: 'private birth details',
        precision: 'inputSnapshot',
      );
      expect(
        event.parameters.keys,
        unorderedEquals(['ad_format', 'placement']),
      );
      final revenue = AnalyticsEvent.adLifecycle(
        action: 'paid',
        format: 'interstitial',
        value: 2000,
        currency: 'USD',
        precision: 'precise',
      );
      expect(revenue.parameters['value_micros'], 2000);
    },
  );
  test('policy store persists atomically; corruption and write failure fail closed', () async {
    SharedPreferences.setMockInitialValues({});
    final disk = SharedPreferencesAdPolicyStore();
    await disk.save('2026-10-26', 10);
    expect(await disk.load(), (viewedDay: '2026-10-26', dismissedMs: 10));
    SharedPreferences.setMockInitialValues({
      SharedPreferencesAdPolicyStore.key: '{broken',
    });
    final corrupt = AdPolicy(store: disk);
    await corrupt.initialize();
    expect(corrupt.skipReason(clock, clock), 'policy_unavailable');
    final policy = AdPolicy(store: store);
    await policy.markViewed(clock);
    store.fail = true;
    await policy.markDismissed(clock);
    expect(policy.skipReason(clock, clock), 'policy_unavailable');
  });

  adTest('production wrapper: two wrappers of one native ad never dispose it', (
    tester,
  ) async {
    await init();
    final request = backend.requests(AdFormat.interstitial).single;
    final native = _NativeInterstitial();
    request.loaded(GoogleFullscreenAd(interstitial: native));
    request.loaded(GoogleFullscreenAd(interstitial: native));
    expect(native.disposeCount, 0);
    expect(service.isInterstitialLoaded, true);
    final shown = inter();
    await tester.pump();
    expect(native.showCount, 1);
    request.loaded(GoogleFullscreenAd(interstitial: native));
    expect(native.disposeCount, 0);
    native.dismiss();
    await shown;
    expect(native.disposeCount, 1);
    // A genuinely different, stale native ad is still disposed.
    final stale = _NativeInterstitial();
    request.loaded(GoogleFullscreenAd(interstitial: stale));
    expect(stale.disposeCount, 1);
  });

  test('the production wrapper reports the native ad as its identity', () {
    final native = _NativeInterstitial();
    expect(
      identical(
        GoogleFullscreenAd(interstitial: native).identity,
        GoogleFullscreenAd(interstitial: native).identity,
      ),
      true,
    );
    expect(
      identical(
        GoogleFullscreenAd(interstitial: native).identity,
        GoogleFullscreenAd(interstitial: _NativeInterstitial()).identity,
      ),
      false,
    );
  });

  group('UMP', () {
    Future<void> resume(WidgetTester tester) async {
      service.setForeground(false);
      service.setForeground(true);
      await tester.pump();
    }

    adTest('update failure with prior permission still serves ads', (
      tester,
    ) async {
      backend.updateSucceeds = false;
      await service.initialize();
      expect(backend.formCount, 0);
      expect(backend.canRequestCount, 1);
      expect(backend.initializeCount, 1);
      expect(backend.loads, hasLength(2));
    });

    adTest('update timeout consults the SDK instead of assuming', (
      tester,
    ) async {
      backend.update = Completer<bool>();
      final init = service.initialize();
      await tester.pump(const Duration(seconds: 14));
      expect(backend.canRequestCount, 0);
      await tester.pump(const Duration(seconds: 1));
      await init;
      expect(backend.formCount, 0);
      expect(backend.canRequestCount, 1);
      expect(backend.loads, hasLength(2));
    });

    adTest('failure without permission stays closed, then recovers once', (
      tester,
    ) async {
      backend
        ..updateSucceeds = false
        ..consent = false;
      await service.initialize();
      expect(backend.loads, isEmpty);
      expect(backend.initializeCount, 0);
      // Too soon: a resume inside the interval does not retry.
      await advance(tester, const Duration(seconds: 30));
      await resume(tester);
      expect(backend.updateCount, 1);
      backend
        ..updateSucceeds = true
        ..consent = true;
      await advance(tester, const Duration(seconds: 30));
      await resume(tester);
      await tester.pump();
      expect(backend.updateCount, 2);
      expect(backend.formCount, 1);
      expect(backend.initializeCount, 1);
      expect(backend.loads, hasLength(2));
      // Recovered: no further consent traffic, and nothing was displayed.
      await advance(tester, const Duration(minutes: 5));
      await resume(tester);
      expect(backend.updateCount, 2);
      expect(backend.ready(AdFormat.interstitial).showCount, 0);
    });

    adTest('SDK start failure is retryable; a refusal is not', (tester) async {
      backend.sdkFails = true;
      await service.initialize();
      expect(backend.loads, isEmpty);
      backend.sdkFails = false;
      await advance(tester, const Duration(minutes: 1));
      await resume(tester);
      await tester.pump();
      expect(backend.initializeCount, 2);
      expect(backend.loads, hasLength(2));

      service.dispose();
      final refused = FakeAdsBackend()..consent = false;
      service = ManagedAdService(
        backend: refused,
        policy: AdPolicy(store: store),
        nowUtc: () => clock,
        nowLocal: () => clock,
      );
      await service.initialize();
      await advance(tester, const Duration(minutes: 5));
      await resume(tester);
      expect(refused.updateCount, 1);
      expect(refused.formCount, 1);
      expect(refused.loads, isEmpty);
    });

    adTest('concurrent initialize and rapid resumes make one attempt', (
      tester,
    ) async {
      backend
        ..update = Completer<bool>()
        ..consent = false;
      final first = service.initialize();
      final second = service.initialize();
      for (var i = 0; i < 5; i++) {
        await resume(tester);
      }
      expect(backend.updateCount, 1);
      await advance(tester, const Duration(seconds: 15));
      await Future.wait([first, second]);
      expect(backend.canRequestCount, 1);
      // Retryable now. A burst of resumes starts exactly one new attempt.
      await advance(tester, const Duration(minutes: 1));
      for (var i = 0; i < 5; i++) {
        await resume(tester);
      }
      expect(backend.updateCount, 2);
      await advance(tester, const Duration(seconds: 15));
      expect(backend.canRequestCount, 2);
    });

    adTest('a late answer from an old attempt cannot change newer state', (
      tester,
    ) async {
      final old = backend.update = Completer<bool>();
      backend.consent = false;
      final init = service.initialize();
      await advance(tester, const Duration(seconds: 15));
      await init;
      expect(backend.loads, isEmpty);
      backend
        ..update = null
        ..consent = true;
      await advance(tester, const Duration(minutes: 1));
      await resume(tester);
      await tester.pump();
      expect(backend.loads, hasLength(2));
      old.complete(false);
      await tester.pump();
      expect(backend.formCount, 1);
      expect(backend.canRequestCount, 2);
      backend.ready(AdFormat.interstitial);
      expect(service.isInterstitialLoaded, true);
    });

    adTest(
      'an unanswered consent form holds the fullscreen guard; no timer frees it',
      (tester) async {
        backend.form = Completer<ConsentFormOutcome>();
        unawaited(service.initialize());
        await tester.pump();
        expect(backend.formCount, 1);
        await advance(tester, const Duration(minutes: 30));
        await resume(tester);
        await service.showPrivacyOptions();
        var grants = 0;
        expect(
          await service.showRewarded(
            onEarnedReward: () async {
              grants++;
            },
          ),
          AdOutcome.skipped,
        );
        await inter(InterstitialPlacement.history);
        expect(backend.updateCount, 1);
        expect(backend.formCount, 1);
        expect(backend.privacyFormCount, 0);
        expect(backend.canRequestCount, 0);
        expect(backend.loads, isEmpty);
        expect(grants, 0);
        // The late dismissal is the evidence; only now does anything start.
        backend.form!.complete(ConsentFormOutcome.completed);
        await tester.pump();
        expect(backend.canRequestCount, 1);
        expect(backend.loads, hasLength(2));
        final ad = backend.ready(AdFormat.interstitial);
        expect(ad.showCount, 0);
      },
    );

    adTest('an open privacy form blocks ads and a second form', (tester) async {
      await init();
      backend.privacyForm = Completer<ConsentFormOutcome>();
      final privacy = service.showPrivacyOptions();
      await tester.pump();
      await service.showPrivacyOptions();
      expect(backend.privacyFormCount, 1);
      expect(
        await service.showRewarded(onEarnedReward: () async {}),
        AdOutcome.skipped,
      );
      await advance(tester, const Duration(minutes: 30));
      expect(service.isInterstitialLoaded, false);
      backend.privacyForm!.complete(ConsentFormOutcome.completed);
      await privacy;
      expect(backend.privacyFormCount, 1);
      expect(backend.requests(AdFormat.interstitial), hasLength(2));
    });

    adTest('privacy-options requirement comes from the SDK', (tester) async {
      backend.privacyRequired = true;
      expect(service.privacyOptionsRequired, false);
      await service.initialize();
      expect(service.privacyOptionsRequired, true);
    });
  });
}
