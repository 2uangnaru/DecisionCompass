import 'dart:async';

import 'package:decision_compass/analytics/analytics_event.dart';
import 'package:decision_compass/services/ad_policy.dart';
import 'package:decision_compass/services/ad_service.dart';
import 'package:decision_compass/services/banner_ad.dart';
import 'package:decision_compass/services/banner_ad_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ads_test_fakes.dart';
import 'analytics/analytics_flow_test.dart' show RecordingAnalytics;
import 'banner_test_fakes.dart';

void main() {
  late FakeBannerBackend backend;
  late ManagedAdService ads;
  late RecordingAnalytics analytics;
  late BannerAdController controller;
  void bannerTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      backend = FakeBannerBackend();
      analytics = RecordingAnalytics();
      ads = ManagedAdService(
        backend: backend,
        policy: AdPolicy(store: MemoryAdPolicyStore()),
      );
      controller = BannerAdController(
        ads: ads,
        backend: backend,
        placement: BannerPlacement.home,
        analytics: analytics,
      );
      try {
        await body(tester);
      } finally {
        controller.dispose();
        ads.dispose();
        await tester.pump();
      }
    });
  }

  Future<FakeBannerHandle> ready(WidgetTester tester) async {
    await ads.initialize();
    controller.configure(width: 360, active: true);
    await tester.pump();
    final ad = backend.banners.last;
    ad.callbacks.loaded();
    return ad;
  }

  bannerTest('no request before consent, during form, or after refusal', (
    tester,
  ) async {
    backend.form = Completer<ConsentFormOutcome>();
    controller.configure(width: 360, active: true);
    await tester.pump();
    expect(backend.banners, isEmpty);
    final init = ads.initialize();
    await tester.pump();
    expect(ads.presentation.value.fullscreenBusy, isTrue);
    expect(backend.banners, isEmpty);
    backend.consent = false;
    backend.form!.complete(ConsentFormOutcome.completed);
    await init;
    await tester.pump();
    expect(backend.banners, isEmpty);
    expect(controller.visibleAd, isNull);
  });

  bannerTest('SDK startup failure cannot request a banner', (tester) async {
    backend.sdkFails = true;
    controller.configure(width: 360, active: true);
    await ads.initialize();
    await tester.pump();
    expect(backend.banners, isEmpty);
  });

  bannerTest(
    'one request despite repeat configure; hidden and zero width do not load',
    (tester) async {
      await ads.initialize();
      controller.configure(width: 360, active: false);
      await tester.pump();
      controller.configure(width: 0, active: true);
      await tester.pump();
      expect(backend.banners, isEmpty);
      controller.configure(width: 360, active: true);
      for (var i = 0; i < 20; i++) {
        controller.configure(width: 360, active: true);
      }
      await tester.pump();
      expect(backend.banners, hasLength(1));
      expect(backend.banners.single.loads, 1);
      backend.banners.single.callbacks.loaded();
      await tester.pump(const Duration(minutes: 2));
      expect(backend.banners, hasLength(1)); // No app-owned refresh timer.
    },
  );

  bannerTest('route/background/fullscreen hide and restore without reloading', (
    tester,
  ) async {
    final ad = await ready(tester);
    expect(controller.visibleAd, same(ad));
    controller.configure(width: 360, active: false);
    expect(controller.visibleAd, isNull);
    controller.configure(width: 360, active: true);
    expect(controller.visibleAd, same(ad));
    ads.setForeground(false);
    expect(controller.visibleAd, isNull);
    ads.setForeground(true);
    expect(controller.visibleAd, same(ad));
    final reward = backend.ready(AdFormat.rewarded);
    final show = ads.showRewarded(onEarnedReward: () async {});
    expect(controller.visibleAd, isNull);
    reward.close();
    await show;
    expect(controller.visibleAd, same(ad));
    expect(backend.banners, hasLength(1));
    expect(ad.disposals, 0);
  });

  bannerTest('privacy options invalidate banners and refusal prevents reload', (
    tester,
  ) async {
    final ad = await ready(tester);
    backend.privacyForm = Completer<ConsentFormOutcome>();
    final privacy = ads.showPrivacyOptions();
    await tester.pump();
    expect(controller.visibleAd, isNull);
    expect(ad.disposals, 1);
    backend.consent = false;
    backend.privacyForm!.complete(ConsentFormOutcome.completed);
    await privacy;
    ad.callbacks.loaded(); // A stale native load is not permission.
    expect(controller.visibleAd, isNull);
    expect(backend.banners, hasLength(1));
  });

  bannerTest('return from permitted privacy form creates fresh banner', (
    tester,
  ) async {
    final ad = await ready(tester);
    await ads.showPrivacyOptions();
    await tester.pump();
    expect(ad.disposals, 1);
    expect(backend.banners, hasLength(2));
  });

  bannerTest(
    'width change disposes old handle and rejects its stale callbacks',
    (tester) async {
      final old = await ready(tester);
      controller.configure(width: 412, active: true);
      await tester.pump();
      expect(old.disposals, 1);
      old.callbacks.loaded();
      expect(controller.visibleAd, isNull);
      final next = backend.banners.last;
      next.callbacks.loaded();
      expect(controller.visibleAd, same(next));
      expect(controller.size!.width, 412);
    },
  );

  bannerTest(
    'initial failure retries with backoff; hidden route pauses retries',
    (tester) async {
      final ad = await ready(tester);
      // A new width starts a fresh, initially unloaded banner.
      controller.configure(width: 412, active: true);
      await tester.pump();
      final failing = backend.banners.last;
      failing.callbacks.failed();
      failing.callbacks.failed();
      expect(failing.disposals, 1);
      await tester.pump(const Duration(seconds: 1));
      expect(backend.banners, hasLength(2));
      await tester.pump(const Duration(seconds: 1));
      expect(backend.banners, hasLength(3));
      backend.banners.last.callbacks.failed();
      controller.configure(width: 412, active: false);
      await tester.pump(const Duration(seconds: 20));
      expect(backend.banners, hasLength(3));
      controller.configure(width: 412, active: true);
      await tester.pump(const Duration(seconds: 3));
      expect(backend.banners, hasLength(3));
      await tester.pump(const Duration(seconds: 1));
      expect(backend.banners, hasLength(4));
      expect(ad.disposals, 1);
    },
  );

  bannerTest('background pauses failure retries and resume schedules one', (
    tester,
  ) async {
    await ads.initialize();
    controller.configure(width: 360, active: true);
    await tester.pump();
    backend.banners.single.callbacks.failed();
    ads.setForeground(false);
    await tester.pump(const Duration(seconds: 10));
    expect(backend.banners, hasLength(1));
    ads.setForeground(true);
    ads.setForeground(true);
    await tester.pump(const Duration(seconds: 2));
    expect(backend.banners, hasLength(2));
  });

  bannerTest(
    'refresh failure leaves SDK in control; every impression and paid callback counted',
    (tester) async {
      final ad = await ready(tester);
      ad.callbacks.impression();
      ad.callbacks.paid(12500, 'USD', 'precise');
      ad.callbacks.failed();
      await tester.pump(const Duration(seconds: 20));
      expect(ad.disposals, 0);
      expect(backend.banners, hasLength(1));
      ad.callbacks.loaded();
      ad.callbacks.impression();
      ad.callbacks.paid(7500, 'EUR', 'estimated');
      ad.callbacks.clicked();
      expect(
        analytics.events.where((e) => e.name == 'app_ad_impression'),
        hasLength(2),
      );
      final paid = analytics.events.where((e) => e.name == 'ad_paid').toList();
      expect(paid.map((e) => e.parameters['value_micros']), [12500.0, 7500.0]);
      expect(paid.first.parameters, {
        'ad_format': 'banner',
        'placement': 'home',
        'value_micros': 12500.0,
        'currency': 'USD',
        'precision': 'precise',
      });
      expect(analytics.events.where((e) => e.name == 'ad_impression'), isEmpty);
    },
  );

  bannerTest(
    'load watchdog rejects late creation and disposes returned handle',
    (tester) async {
      backend.pendingCreation = Completer<BannerHandle?>();
      await ads.initialize();
      controller.configure(width: 360, active: true);
      await tester.pump();
      final stale = backend.banners.single;
      await tester.pump(const Duration(seconds: 15));
      backend.pendingCreation!.complete(stale);
      backend.pendingCreation = null;
      await tester.pump();
      expect(stale.disposals, 1);
      expect(stale.loads, 0);
      stale.callbacks.loaded();
      expect(controller.visibleAd, isNull);
      await tester.pump(const Duration(seconds: 2));
      expect(backend.banners, hasLength(2));
    },
  );

  bannerTest('native load timeout ignores stale load callbacks after retry', (
    tester,
  ) async {
    await ads.initialize();
    controller.configure(width: 360, active: true);
    await tester.pump();
    final old = backend.banners.single;
    await tester.pump(const Duration(seconds: 15));
    expect(old.disposals, 1);
    await tester.pump(const Duration(seconds: 2));
    final fresh = backend.banners.last;
    old.callbacks.loaded();
    old.callbacks.impression();
    old.callbacks.failed();
    expect(controller.visibleAd, isNull);
    fresh.callbacks.loaded();
    expect(controller.visibleAd, same(fresh));
  });

  for (final stage in ['create', 'load', 'size']) {
    bannerTest('safe $stage failure never escapes or copies SDK payload', (
      tester,
    ) async {
      backend.throwOnCreate = stage == 'create';
      backend.throwOnBannerLoad = stage == 'load';
      backend.noSize = stage == 'size';
      await ads.initialize();
      controller.configure(width: 360, active: true);
      await tester.pump();
      expect(controller.visibleAd, isNull);
      expect(
        analytics.events.where((e) => e.name == 'ad_load_failed'),
        hasLength(1),
      );
      expect(
        analytics.events.map((e) => e.parameters.toString()).join(),
        isNot(contains('sdk-private')),
      );
    });
  }

  bannerTest(
    'banner overlay guards rewarded and privacy flow until real closure',
    (tester) async {
      final ad = await ready(tester);
      backend.ready(AdFormat.rewarded);
      ad.callbacks.opened();
      ad.callbacks.opened();
      expect(controller.visibleAd, isNull);
      expect(
        await ads.showRewarded(onEarnedReward: () async {}),
        AdOutcome.skipped,
      );
      await ads.showPrivacyOptions();
      expect(backend.privacyFormCount, 0);
      controller.dispose();
      expect(ads.presentation.value.fullscreenBusy, isTrue);
      ad.callbacks.closed();
      expect(ads.presentation.value.fullscreenBusy, isFalse);
      ad.callbacks.closed();
    },
  );

  bannerTest(
    'service disposal clears banners and late callbacks cannot resurrect them',
    (tester) async {
      final ad = await ready(tester);
      ads.dispose();
      expect(ad.disposals, 1);
      expect(controller.visibleAd, isNull);
      ad.callbacks.loaded();
      ad.callbacks.failed();
      await tester.pump(const Duration(seconds: 20));
      expect(backend.banners, hasLength(1));
    },
  );

  bannerTest(
    'late paid survives slot disposal without granting reward or changing policy',
    (tester) async {
      final ad = await ready(tester);
      controller.dispose();
      ad.callbacks.loaded();
      ad.callbacks.paid(99, 'USD', 'precise');
      expect(analytics.events.where((e) => e.name == 'ad_paid'), hasLength(1));
      expect(ads.presentation.value.fullscreenBusy, isFalse);
    },
  );

  for (final hiddenBy in ['route', 'background']) {
    bannerTest(
      'async sizing cannot start network load after $hiddenBy hides slot',
      (tester) async {
        backend.pendingCreation = Completer<BannerHandle?>();
        await ads.initialize();
        controller.configure(width: 360, active: true);
        await tester.pump();
        final late = backend.banners.single;
        if (hiddenBy == 'route') {
          controller.configure(width: 360, active: false);
        } else {
          ads.setForeground(false);
        }
        backend.pendingCreation!.complete(late);
        backend.pendingCreation = null;
        await tester.pump();
        expect(late.loads, 0);
        expect(late.disposals, 1);
        expect(controller.visibleAd, isNull);
        controller.configure(width: 360, active: true);
        ads.setForeground(true);
        await tester.pump();
        expect(backend.banners, hasLength(2));
        expect(backend.banners.last.loads, 1);
      },
    );
  }

  test(
    'banner telemetry vocabulary is closed and strips invalid paid fields',
    () {
      expect(
        () => AnalyticsEvent.adLifecycle(
          action: 'request',
          format: 'banner',
          placement: 'raw-user-text',
        ),
        throwsArgumentError,
      );
      final event = AnalyticsEvent.adLifecycle(
        action: 'paid',
        format: 'banner',
        placement: 'reveal',
        value: double.nan,
        currency: 'birthDate',
        precision: 'sdk-private',
      );
      expect(event.parameters, {'ad_format': 'banner', 'placement': 'reveal'});
    },
  );
}
