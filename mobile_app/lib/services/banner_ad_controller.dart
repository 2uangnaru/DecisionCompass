import 'dart:async';

import 'package:flutter/foundation.dart';

import '../analytics/analytics_event.dart';
import '../analytics/analytics_service.dart';
import 'ad_runtime.dart';
import 'banner_ad.dart';

/// One native banner per mounted slot, never shared between two AdWidgets.
/// The hidden Home route can retain its own banner while Reveal owns another.
/// SDK auto-refresh owns subsequent requests; there is no app refresh timer.
class BannerAdController extends ChangeNotifier {
  BannerAdController({
    required this.ads,
    required this.backend,
    required this.placement,
    this.analytics = const NoopAnalyticsService(),
  }) {
    ads.presentation.addListener(_reconcile);
  }

  final AdService ads;
  final BannerBackend backend;
  final BannerPlacement placement;
  final AnalyticsService analytics;
  static const loadTimeout = Duration(seconds: 15);
  BannerHandle? _ad;
  BannerSize? _size;
  bool _active = false, _loading = false, _loaded = false, _disposed = false;
  int _width = 0, _generation = 0, _failures = 0;
  Timer? _timeout, _retry;

  BannerSize? get size => _size;
  int get width => _width;
  BannerHandle? get visibleAd =>
      !_disposed && _active && ads.presentation.value.canPresent && _loaded
      ? _ad
      : null;

  /// Called after layout, not from build. Repeated builds/ticks are no-ops.
  void configure({required int width, required bool active}) {
    if (_disposed || (_width == width && _active == active)) return;
    if (_width != width) {
      _invalidate();
      _size = null;
      _width = width;
      _failures = 0;
    }
    _active = active;
    _reconcile();
  }

  bool get _mayLoad =>
      !_disposed && _active && _width > 0 && ads.presentation.value.canPresent;

  void _reconcile() {
    if (_disposed) return;
    if (!ads.presentation.value.canRequestAds) {
      // Withdrawal/form collection invalidates even a hidden route's banner.
      _invalidate();
      _failures = 0;
    } else if (!_mayLoad) {
      _retry?.cancel();
      _retry = null;
    } else if (_ad == null && !_loading && _retry == null) {
      if (_failures > 0) {
        _scheduleRetry();
      } else {
        unawaited(_load());
      }
    }
    notifyListeners();
  }

  void _event(
    String action, {
    String? reason,
    double? value,
    String? currency,
    String? precision,
  }) {
    try {
      analytics.record(
        AnalyticsEvent.adLifecycle(
          action: action,
          format: 'banner',
          placement: placement.name,
          reason: reason,
          value: value,
          currency: currency,
          precision: precision,
        ),
      );
    } catch (_) {
      // Optional telemetry cannot block content or expose SDK error text.
    }
  }

  Future<void> _load() async {
    if (!_mayLoad || _loading || _ad != null) return;
    _loading = true;
    final generation = ++_generation;
    bool current() => !_disposed && generation == _generation;
    var accepted = false;
    var overlayOpened = false;
    void failed(String reason) {
      if (!current()) return;
      _event('load_failed', reason: reason);
      // Once initially loaded, retain the view: SDK auto-refresh handles
      // refresh failures. Never run a second retry loop beside that SDK.
      if (_loaded) return;
      _invalidate();
      _failures++;
      _scheduleRetry();
      notifyListeners();
    }

    _timeout = Timer(loadTimeout, () => failed('load_timeout'));
    _event('request');
    try {
      final handle = await backend.createBanner(
        width: _width,
        callbacks: BannerCallbacks(
          loaded: () {
            if (!current() || _ad == null) return;
            _timeout?.cancel();
            accepted = true;
            _loading = false;
            _loaded = true;
            _failures = 0;
            _event('loaded');
            notifyListeners();
          },
          failed: () => failed('sdk_load_failed'),
          impression: () {
            if (current() && accepted) _event('impression');
          },
          clicked: () {
            if (current() && accepted) _event('clicked');
          },
          opened: () {
            if (!current() || !accepted || overlayOpened) return;
            overlayOpened = true;
            ads.setBannerOverlayOpen(true);
          },
          closed: () {
            // A native overlay may outlive its originating route. Only the
            // actual SDK closure releases the guard, even after disposal.
            if (!overlayOpened) return;
            overlayOpened = false;
            ads.setBannerOverlayOpen(false);
          },
          paid: (value, currency, precision) {
            // Refreshes reuse the native banner but earn separate revenue.
            // Do not deduplicate once per handle or discard late revenue.
            if (accepted) {
              _event(
                'paid',
                value: value,
                currency: currency,
                precision: precision,
              );
            }
          },
        ),
      );
      if (!current() || !_mayLoad) {
        if (handle != null) _discard(handle);
        // Sizing can finish after the route was covered or app paused.
        // Do not start the native network load from that late continuation.
        if (current()) {
          _invalidate();
          notifyListeners();
        }
        return;
      }
      if (handle == null ||
          handle.size.width <= 0 ||
          handle.size.width > _width ||
          handle.size.height <= 0 ||
          handle.size.height > 90) {
        if (handle != null) _discard(handle);
        failed('load_exception');
        return;
      }
      _ad = handle;
      _size = handle.size;
      // Geometry resolves before the creative loads, so a creative refresh
      // never changes the slot's height or moves buttons.
      notifyListeners();
      await handle.load();
    } catch (_) {
      failed('load_exception');
    }
  }

  void _scheduleRetry() {
    if (!_mayLoad || _retry != null) return;
    final seconds = 1 << _failures.clamp(1, 6);
    _retry = Timer(Duration(seconds: seconds), () {
      _retry = null;
      unawaited(_load());
    });
  }

  void _discard(BannerHandle ad) {
    unawaited(Future<void>.sync(ad.dispose).catchError((Object _) {}));
  }

  void _invalidate() {
    _generation++;
    _timeout?.cancel();
    _retry?.cancel();
    _timeout = _retry = null;
    _loading = _loaded = false;
    final ad = _ad;
    _ad = null;
    if (ad != null) _discard(ad);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    ads.presentation.removeListener(_reconcile);
    _invalidate();
    super.dispose();
  }
}
