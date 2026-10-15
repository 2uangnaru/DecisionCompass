import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Configuration constants for AdMob.
class AdConstants {
  // ===========================================================================
  // CẤU HÌNH ADMOB ID
  // Hiện tại đang dùng TEST AD UNIT ID CHÍNH THỨC CỦA GOOGLE.
  // Khi bạn đã có ID thật từ Google AdMob, chỉ cần thay các chuỗi dưới đây:
  // ===========================================================================

  /// Android Test Interstitial Ad Unit ID của Google
  static const String testAndroidInterstitialUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  /// iOS Test Interstitial Ad Unit ID của Google
  static const String testIosInterstitialUnitId =
      'ca-app-pub-3940256099942544/4411468910';

  /// TODO: Điền ID thật cho Android tại đây khi có tài khoản AdMob
  static const String? realAndroidInterstitialUnitId = null;

  /// TODO: Điền ID thật cho iOS tại đây khi có tài khoản AdMob
  static const String? realIosInterstitialUnitId = null;

  /// Lấy Ad Unit ID phù hợp theo nền tảng
  static String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return realAndroidInterstitialUnitId ?? testAndroidInterstitialUnitId;
    }
    if (Platform.isIOS) {
      return realIosInterstitialUnitId ?? testIosInterstitialUnitId;
    }
    return '';
  }
}

/// Abstract contract for ad handling across the app.
abstract interface class AdService {
  Future<void> initialize();
  void preloadInterstitial();
  Future<void> showInterstitial({required VoidCallback onDismissed});
  bool get isInterstitialLoaded;
}

/// No-op implementation for headless tests and unsupported platforms.
class NoOpAdService implements AdService {
  const NoOpAdService();

  @override
  Future<void> initialize() async {}

  @override
  void preloadInterstitial() {}

  @override
  Future<void> showInterstitial({required VoidCallback onDismissed}) async {
    onDismissed();
  }

  @override
  bool get isInterstitialLoaded => false;
}

/// Production AdMob implementation.
class AdMobService implements AdService {
  AdMobService({this.adUnitId});

  final String? adUnitId;
  InterstitialAd? _interstitialAd;
  bool _isAdLoading = false;
  bool _initialized = false;

  String get _resolvedUnitId => adUnitId ?? AdConstants.interstitialAdUnitId;

  @override
  bool get isInterstitialLoaded => _interstitialAd != null;

  @override
  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      preloadInterstitial();
    } catch (e) {
      debugPrint('[AdService] MobileAds initialize failed: $e');
    }
  }

  @override
  void preloadInterstitial() {
    if (kIsWeb || _interstitialAd != null || _isAdLoading) return;
    final unitId = _resolvedUnitId;
    if (unitId.isEmpty) return;

    _isAdLoading = true;
    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoading = false;
          debugPrint('[AdService] Interstitial Ad loaded successfully.');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isAdLoading = false;
          debugPrint('[AdService] Interstitial Ad failed to load: ${error.message}');
        },
      ),
    );
  }

  @override
  Future<void> showInterstitial({required VoidCallback onDismissed}) async {
    final ad = _interstitialAd;
    if (ad == null) {
      debugPrint('[AdService] No Interstitial Ad ready. Bypassing safely.');
      preloadInterstitial();
      onDismissed();
      return;
    }

    final completer = Completer<void>();
    var handled = false;
    void completeOnce() {
      if (!handled) {
        handled = true;
        onDismissed();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    }

    // Safety timeout: In case the native ad view hangs or doesn't invoke callbacks within 8s
    final timer = Timer(const Duration(seconds: 8), () {
      if (!handled) {
        debugPrint('[AdService] Interstitial Ad timeout. Bypassing.');
        completeOnce();
      }
    });

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        timer.cancel();
        ad.dispose();
        _interstitialAd = null;
        preloadInterstitial();
        completeOnce();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        timer.cancel();
        ad.dispose();
        _interstitialAd = null;
        debugPrint('[AdService] Failed to show Interstitial Ad: ${error.message}');
        preloadInterstitial();
        completeOnce();
      },
    );

    try {
      await ad.show();
    } catch (e) {
      timer.cancel();
      _interstitialAd = null;
      debugPrint('[AdService] Exception while showing ad: $e');
      preloadInterstitial();
      completeOnce();
    }

    return completer.future;
  }
}
