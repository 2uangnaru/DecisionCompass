import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../analytics/analytics_service.dart';
import 'ad_policy.dart';
import 'ad_runtime.dart';
import 'banner_ad.dart';
export 'ad_runtime.dart';

/// Google's TEST units. No production ad IDs are configured by this change.
class AdConstants {
  static const testAndroidInterstitialUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const testIosInterstitialUnitId =
      'ca-app-pub-3940256099942544/4411468910';
  static const testAndroidRewardedUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const testIosRewardedUnitId = 'ca-app-pub-3940256099942544/1712485313';
  static const testAndroidBannerUnitId =
      'ca-app-pub-3940256099942544/9214589741';
  static const testIosBannerUnitId = 'ca-app-pub-3940256099942544/2435281174';
  // Empty until the owner supplies production units. No live ads by default.
  static const realAndroidBannerUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER_UNIT_ID',
  );
  static const realIosBannerUnitId = String.fromEnvironment(
    'ADMOB_IOS_BANNER_UNIT_ID',
  );
  static String get bannerAdUnitId => kIsWeb
      ? ''
      : Platform.isAndroid
      ? (realAndroidBannerUnitId.isEmpty
            ? testAndroidBannerUnitId
            : realAndroidBannerUnitId)
      : Platform.isIOS
      ? (realIosBannerUnitId.isEmpty
            ? testIosBannerUnitId
            : realIosBannerUnitId)
      : '';
  static const String? realAndroidInterstitialUnitId = null;
  static const String? realIosInterstitialUnitId = null;
  static String get interstitialAdUnitId => kIsWeb
      ? ''
      : Platform.isAndroid
      ? realAndroidInterstitialUnitId ?? testAndroidInterstitialUnitId
      : Platform.isIOS
      ? realIosInterstitialUnitId ?? testIosInterstitialUnitId
      : '';
  static String get rewardedAdUnitId => kIsWeb
      ? ''
      : Platform.isAndroid
      ? testAndroidRewardedUnitId
      : Platform.isIOS
      ? testIosRewardedUnitId
      : '';
}

class AdMobService extends ManagedAdService {
  AdMobService({
    String? adUnitId,
    AnalyticsService analytics = const NoopAnalyticsService(),
  }) : super(
         backend: GoogleAdsBackend(interstitialUnit: adUnitId),
         policy: AdPolicy(store: SharedPreferencesAdPolicyStore()),
         analytics: analytics,
       );
}

class GoogleAdsBackend implements AdsBackend, BannerBackend {
  GoogleAdsBackend({this.interstitialUnit, this.bannerUnit});
  final String? interstitialUnit;
  final String? bannerUnit;
  Future<void>? _sdkInitialization;

  Future<void> _initializeSdk() => _sdkInitialization ??= _startSdk();
  Future<void> _startSdk() async {
    try {
      await MobileAds.instance.initialize();
    } catch (_) {
      _sdkInitialization = null;
      rethrow;
    }
  }

  /// No ad units on this platform: nothing to gather, and no ads.
  static bool get _supported => AdConstants.interstitialAdUnitId.isNotEmpty;

  @override
  Future<bool> updateConsentInfo() {
    if (!_supported) return Future.value(true);
    final done = Completer<bool>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        if (!done.isCompleted) done.complete(true);
      },
      (_) {
        if (!done.isCompleted) done.complete(false);
      },
    );
    return done.future;
  }

  // Both plugin futures complete from the native dismissal listener, so
  // their completion is the closure signal the coordinator waits for.
  // Their callback carries FormError separately: a resolved Future<void>
  // alone does not distinguish a loaded/dismissed form from a failed load.
  @visibleForTesting
  static Future<ConsentFormOutcome> presentForm(
    Future<void> Function(OnConsentFormDismissedListener) present,
  ) async {
    var outcome = ConsentFormOutcome.failed;
    await present((error) {
      outcome = error == null
          ? ConsentFormOutcome.completed
          : ConsentFormOutcome.failed;
    });
    return outcome;
  }

  @override
  Future<ConsentFormOutcome> showConsentFormIfRequired() => _supported
      ? presentForm(ConsentForm.loadAndShowConsentFormIfRequired)
      : Future.value(ConsentFormOutcome.completed);
  @override
  Future<ConsentFormOutcome> showPrivacyOptionsForm() => _supported
      ? presentForm(ConsentForm.showPrivacyOptionsForm)
      : Future.value(ConsentFormOutcome.completed);
  @override
  Future<bool> canRequestAds() => _supported
      ? ConsentInformation.instance.canRequestAds()
      : Future.value(false);
  @override
  Future<bool> privacyOptionsRequired() async =>
      _supported &&
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
  @override
  Future<void> initializeSdk() => _initializeSdk();

  @override
  Future<BannerHandle?> createBanner({
    required int width,
    required BannerCallbacks callbacks,
  }) async {
    final unit = bannerUnit ?? AdConstants.bannerAdUnitId;
    if (unit.isEmpty) return null;
    // v9.1 deprecates the compact anchored API in favour of LARGE anchored
    // (up to 150dp). Retain the standard 50-90dp format agreed for this UI;
    // adopting the taller format is a product/layout change, not a rename.
    // ignore: deprecated_member_use
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );
    if (size == null) return null;
    return GoogleBannerHandle(
      BannerAd(
        adUnitId: unit,
        size: size,
        // Ordinary anchored banner, deliberately not collapsible.
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) => callbacks.loaded(),
          onAdFailedToLoad: (_, _) => callbacks.failed(),
          onAdImpression: (_) => callbacks.impression(),
          onAdClicked: (_) => callbacks.clicked(),
          onAdOpened: (_) => callbacks.opened(),
          onAdClosed: (_) => callbacks.closed(),
          onPaidEvent: (_, value, precision, currency) =>
              callbacks.paid(value, currency, precision.name),
        ),
      ),
    );
  }

  @override
  Future<void> load(
    AdFormat format,
    void Function(FullscreenAd) onLoaded,
    VoidCallback onFailed,
  ) {
    if (format == AdFormat.interstitial) {
      return InterstitialAd.load(
        adUnitId: interstitialUnit ?? AdConstants.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) => onLoaded(GoogleFullscreenAd(interstitial: ad)),
          onAdFailedToLoad: (_) => onFailed(),
        ),
      );
    }
    return RewardedAd.load(
      adUnitId: AdConstants.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => onLoaded(GoogleFullscreenAd(rewarded: ad)),
        onAdFailedToLoad: (_) => onFailed(),
      ),
    );
  }
}

@visibleForTesting
class GoogleBannerHandle implements BannerHandle {
  GoogleBannerHandle(this.ad);
  final BannerAd ad;
  bool _disposed = false;
  @override
  BannerSize get size => BannerSize(ad.size.width, ad.size.height);
  @override
  Future<void> load() => ad.load();
  @override
  Widget buildView() => AdWidget(key: ObjectKey(ad), ad: ad);
  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    // Let the slot remove AdWidget before destroying its native ad/view.
    await WidgetsBinding.instance.endOfFrame;
    await ad.dispose();
  }
}

/// Public only so tests can prove the identity the coordinator relies on.
@visibleForTesting
class GoogleFullscreenAd implements FullscreenAd {
  GoogleFullscreenAd({this.interstitial, this.rewarded})
    : assert((interstitial == null) != (rewarded == null));
  final InterstitialAd? interstitial;
  final RewardedAd? rewarded;

  /// The native ad: a fresh wrapper per load callback must not look new.
  @override
  Object get identity => (interstitial ?? rewarded)!;
  @override
  Future<void> show({
    required VoidCallback onDismissed,
    required VoidCallback onFailed,
    required VoidCallback onImpression,
    required VoidCallback onClick,
    required void Function(double, String, String) onPaid,
    required VoidCallback onReward,
  }) {
    FullScreenContentCallback<T> callbacks<T extends Ad>() =>
        FullScreenContentCallback<T>(
          onAdDismissedFullScreenContent: (_) => onDismissed(),
          onAdFailedToShowFullScreenContent: (_, _) => onFailed(),
          onAdImpression: (_) => onImpression(),
          onAdClicked: (_) => onClick(),
        );
    void paid(Ad _, double value, PrecisionType precision, String currency) =>
        onPaid(value, currency, precision.name);
    if (interstitial != null) {
      interstitial!.fullScreenContentCallback = callbacks<InterstitialAd>();
      interstitial!.onPaidEvent = paid;
      return interstitial!.show();
    }
    rewarded!.fullScreenContentCallback = callbacks<RewardedAd>();
    rewarded!.onPaidEvent = paid;
    return rewarded!.show(onUserEarnedReward: (_, _) => onReward());
  }

  @override
  Future<void> dispose() => (interstitial ?? rewarded!).dispose();
}
