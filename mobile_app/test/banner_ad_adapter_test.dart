import 'package:decision_compass/services/ad_service.dart';
import 'package:decision_compass/services/banner_ad.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class _NativeBanner extends Fake implements BannerAd {
  @override
  AdSize get size => const AdSize(width: 360, height: 50);
  int loads = 0, disposals = 0;
  @override
  Future<void> load() async => loads++;
  @override
  Future<void> dispose() async => disposals++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'production handle uses native size/view and disposes once AFTER frame',
    (tester) async {
      final native = _NativeBanner();
      final handle = GoogleBannerHandle(native);
      expect(handle.size.width, 360);
      expect(handle.size.height, 50);
      expect((handle.buildView() as AdWidget).ad, same(native));
      await handle.load();
      expect(native.loads, 1);
      final disposed = handle.dispose();
      handle.dispose();
      expect(native.disposals, 0);
      await tester.pump();
      await disposed;
      expect(native.disposals, 1);
    },
  );

  testWidgets(
    'production backend creates standard adaptive request and maps native callbacks',
    (tester) async {
      const channel = MethodChannel('plugins.flutter.io/google_mobile_ads');
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        if (call.method == 'AdSize#getAnchoredAdaptiveBannerAdSize') return 50;
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final events = <String>[];
      final backend = GoogleAdsBackend(
        bannerUnit: AdConstants.testAndroidBannerUnitId,
      );
      final handle = await backend.createBanner(
        width: 360,
        callbacks: BannerCallbacks(
          loaded: () => events.add('loaded'),
          failed: () => events.add('failed'),
          impression: () => events.add('impression'),
          clicked: () => events.add('clicked'),
          opened: () => events.add('opened'),
          closed: () => events.add('closed'),
          paid: (value, currency, precision) =>
              events.add('$value/$currency/$precision'),
        ),
      ) as GoogleBannerHandle;
      expect(calls.single.method, 'AdSize#getAnchoredAdaptiveBannerAdSize');
      expect(calls.single.arguments, {'width': 360});
      expect(handle.ad.adUnitId, AdConstants.testAndroidBannerUnitId);
      expect(handle.ad.size, isA<AnchoredAdaptiveBannerAdSize>());
      expect(handle.ad.request.extras, isNull); // No collapsible flag.
      final listener = handle.ad.listener;
      listener.onAdLoaded!(handle.ad);
      listener.onAdImpression!(handle.ad);
      listener.onAdClicked!(handle.ad);
      listener.onAdOpened!(handle.ad);
      listener.onAdClosed!(handle.ad);
      listener.onPaidEvent!(handle.ad, 12500, PrecisionType.precise, 'USD');
      listener.onAdFailedToLoad!(
        handle.ad,
        LoadAdError(3, 'private', 'private-birthDate', null),
      );
      expect(events, [
        'loaded',
        'impression',
        'clicked',
        'opened',
        'closed',
        '12500.0/USD/precise',
        'failed',
      ]);
    },
  );
}
