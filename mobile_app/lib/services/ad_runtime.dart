import 'dart:async';

import 'package:flutter/foundation.dart';

import '../analytics/analytics_event.dart';
import '../analytics/analytics_service.dart';
import 'ad_policy.dart';

enum AdFormat { interstitial, rewarded }

enum InterstitialPlacement { afterAnalysis, history }

/// A completed form operation is not permission to request ads. Permission
/// still comes exclusively from UMP's canRequestAds(). A pending operation
/// has no outcome: it must keep the fullscreen guard held.
enum ConsentFormOutcome { completed, failed }

/// [rewardSaveFailed]: the SDK reported the reward as earned, but saving it
/// failed, so nothing was granted. It is never used for a voluntary close.
enum AdOutcome { skipped, dismissed, rewarded, failed, rewardSaveFailed }

/// Testable SDK boundary: SDK errors, profile data and response text stay out.
abstract interface class FullscreenAd {
  /// The native ad this wraps. An adapter may deliver one native ad through
  /// several wrappers; they must all report the same identity.
  Object get identity;
  Future<void> show({
    required VoidCallback onDismissed,
    required VoidCallback onFailed,
    required VoidCallback onImpression,
    required VoidCallback onClick,
    required void Function(double, String, String) onPaid,
    required VoidCallback onReward,
  });
  Future<void> dispose();
}

/// Thin UMP/SDK primitives. Ordering, timeouts and retry live in
/// [ManagedAdService], where they can be tested without the native SDK.
abstract interface class AdsBackend {
  /// Consent-info update: true on success, false on an SDK error. It may never
  /// complete.
  Future<bool> updateConsentInfo();

  /// Completes once a required consent form has been dismissed, or could not
  /// be shown. It may never complete, and that is NOT evidence that a form
  /// closed.
  Future<ConsentFormOutcome> showConsentFormIfRequired();

  /// Same closure semantics as [showConsentFormIfRequired].
  Future<ConsentFormOutcome> showPrivacyOptionsForm();
  Future<bool> canRequestAds();
  Future<bool> privacyOptionsRequired();
  Future<void> initializeSdk();
  Future<void> load(
    AdFormat format,
    void Function(FullscreenAd) onLoaded,
    VoidCallback onFailed,
  );
}

abstract class AdService {
  Future<void> initialize();
  void preloadInterstitial();
  void preloadRewarded();
  bool get isInterstitialLoaded;
  bool get isRewardedLoaded;
  bool get privacyOptionsRequired;
  Future<void> showPrivacyOptions();
  Future<void> markReadingViewed(DateTime local);
  Future<void> showInterstitial({
    required VoidCallback onDismissed,
    InterstitialPlacement placement = InterstitialPlacement.afterAnalysis,
  });
  Future<AdOutcome> showRewarded({
    required Future<void> Function() onEarnedReward,
    String placement = 'reading',
  });
  void setForeground(bool value);
  void dispose();
}

class NoOpAdService implements AdService {
  const NoOpAdService();
  @override
  Future<void> initialize() async {}
  @override
  void preloadInterstitial() {}
  @override
  void preloadRewarded() {}
  @override
  bool get isInterstitialLoaded => false;
  @override
  bool get isRewardedLoaded => false;
  @override
  bool get privacyOptionsRequired => false;
  @override
  Future<void> showPrivacyOptions() async {}
  @override
  Future<void> markReadingViewed(DateTime local) async {}
  @override
  Future<void> showInterstitial({
    required VoidCallback onDismissed,
    InterstitialPlacement placement = InterstitialPlacement.afterAnalysis,
  }) async => onDismissed();
  @override
  Future<AdOutcome> showRewarded({
    required Future<void> Function() onEarnedReward,
    String placement = 'reading',
  }) async => AdOutcome.skipped;
  @override
  void setForeground(bool value) {}
  @override
  void dispose() {}
}

class _Slot {
  FullscreenAd? ad;
  DateTime? loadedAt;
  bool loading = false;
  int generation = 0;
  int failures = 0;
  Timer? timeout;
  Timer? retry;
  Timer? expiry;
}

/// One cached ad/format and one fullscreen lock across both formats.
/// No future load ever replays a skipped placement.
class ManagedAdService implements AdService {
  ManagedAdService({
    required this.backend,
    required this.policy,
    this.analytics = const NoopAnalyticsService(),
    DateTime Function()? nowUtc,
    DateTime Function()? nowLocal,
  }) : nowUtc = nowUtc ?? _utc,
       nowLocal = nowLocal ?? DateTime.now;
  final AdsBackend backend;
  final AdPolicy policy;
  final AnalyticsService analytics;
  final DateTime Function() nowUtc;
  final DateTime Function() nowLocal;
  static DateTime _utc() => DateTime.now().toUtc();
  static const cacheLifetime = Duration(minutes: 50);
  static const loadTimeout = Duration(seconds: 15);

  /// Bound on each UMP step that shows no UI. Never applied to a form.
  static const consentTimeout = Duration(seconds: 15);

  /// Minimum spacing between consent attempts started by a resume.
  static const consentRetryInterval = Duration(minutes: 1);
  final _slots = {for (final format in AdFormat.values) format: _Slot()};
  Future<void>? _initializing;

  /// The one consent gather or privacy-options flow in progress.
  Future<void>? _consentWork;
  int _consentGeneration = 0;
  DateTime? _consentStartedAt;
  bool _consentRetryable = false, _privacyRequired = false;
  bool _allowed = false,
      _foreground = true,
      _disposed = false,
      _fullscreen = false;

  void _event(
    String action,
    AdFormat format, {
    String? placement,
    String? reason,
    double? value,
    String? currency,
    String? precision,
  }) {
    try {
      analytics.record(
        AnalyticsEvent.adLifecycle(
          action: action,
          format: format.name,
          placement: placement,
          reason: reason,
          value: value,
          currency: currency,
          precision: precision,
        ),
      );
    } catch (_) {
      /* Telemetry must never block content/rewards. */
    }
  }

  @override
  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    await policy.initialize();
    await _exclusive(_gatherConsent);
  }

  /// Joins the consent flow already running rather than starting a second.
  Future<void> _exclusive(Future<void> Function() body) =>
      _consentWork ??= body().whenComplete(() => _consentWork = null);

  bool _consentCurrent(int generation) =>
      !_disposed && generation == _consentGeneration;

  Future<T?> _bounded<T>(Future<T> Function() step) async {
    try {
      return await Future<T>.sync(step).timeout(consentTimeout);
    } catch (_) {
      return null;
    }
  }

  /// A UMP form may be on screen until [form] completes. No timer releases
  /// the guard: a timeout says nothing about whether the form closed.
  Future<ConsentFormOutcome> _holdingFullscreen(
    Future<ConsentFormOutcome> Function() form,
  ) async {
    _fullscreen = true;
    try {
      return await form();
    } catch (_) {
      // Preserve the existing SDK contract for a failed form operation, but
      // do not confuse that failure with a successfully completed choice.
      return ConsentFormOutcome.failed;
    } finally {
      _fullscreen = false;
    }
  }

  Future<void> _gatherConsent() async {
    if (_disposed) return;
    final generation = ++_consentGeneration;
    _consentStartedAt = nowUtc();
    final updated = await _bounded(backend.updateConsentInfo) ?? false;
    if (!_consentCurrent(generation)) return;
    var collectionCompleted = false;
    if (updated) {
      final outcome = await _holdingFullscreen(
        backend.showConsentFormIfRequired,
      );
      if (!_consentCurrent(generation)) return;
      collectionCompleted = outcome == ConsentFormOutcome.completed;
    }
    await _settleConsent(generation, collectionCompleted: collectionCompleted);
  }

  /// After an update error or timeout, UMP may still hold consent from an
  /// earlier session. Ask the SDK; never assume either answer.
  Future<void> _settleConsent(
    int generation, {
    required bool collectionCompleted,
  }) async {
    final allowed = await _bounded(backend.canRequestAds);
    final required = await _bounded(backend.privacyOptionsRequired);
    if (!_consentCurrent(generation)) return;
    if (required != null) _privacyRequired = required;
    var ready = false;
    if (allowed == true) {
      ready =
          await _bounded(() async {
            await backend.initializeSdk();
            return true;
          }) ??
          false;
      if (!_consentCurrent(generation)) return;
    }
    _allowed = ready;
    // Only a completed collection can suppress re-prompting for this session.
    // An update succeeding does NOT mean a form loaded or the reader answered.
    _consentRetryable = !ready && !(collectionCompleted && allowed == false);
    preloadInterstitial();
    preloadRewarded();
  }

  void _retryConsentOnResume() {
    if (_initializing == null ||
        _consentWork != null ||
        _allowed ||
        !_consentRetryable ||
        _fullscreen ||
        _disposed) {
      return;
    }
    final started = _consentStartedAt;
    if (started != null) {
      final age = nowUtc().difference(started);
      if (age >= Duration.zero && age < consentRetryInterval) return;
    }
    unawaited(_exclusive(_gatherConsent));
  }

  @override
  bool get privacyOptionsRequired => _privacyRequired;
  @override
  Future<void> showPrivacyOptions() async {
    if (_disposed || _fullscreen || !_foreground || _consentWork != null) {
      return;
    }
    await _exclusive(() async {
      final generation = ++_consentGeneration;
      _consentStartedAt = nowUtc();
      _allowed = false;
      _clearSlots();
      final outcome = await _holdingFullscreen(backend.showPrivacyOptionsForm);
      if (!_consentCurrent(generation)) return;
      await _settleConsent(
        generation,
        collectionCompleted: outcome == ConsentFormOutcome.completed,
      );
    });
  }

  @override
  Future<void> markReadingViewed(DateTime local) => policy.markViewed(local);
  bool _valid(_Slot slot) {
    if (slot.ad == null || slot.loadedAt == null) return false;
    final age = nowUtc().difference(slot.loadedAt!);
    return age >= Duration.zero && age < cacheLifetime;
  }

  @override
  bool get isInterstitialLoaded => _valid(_slots[AdFormat.interstitial]!);
  @override
  bool get isRewardedLoaded => _valid(_slots[AdFormat.rewarded]!);
  @override
  void preloadInterstitial() => _load(AdFormat.interstitial);
  @override
  void preloadRewarded() => _load(AdFormat.rewarded);
  void _discard(FullscreenAd ad) {
    unawaited(Future<void>.sync(ad.dispose).catchError((Object _) {}));
  }

  void _load(AdFormat format) {
    if (_disposed || !_allowed || !_foreground) return;
    final slot = _slots[format]!;
    if (slot.loading || slot.retry != null || _valid(slot)) return;
    final expired = slot.ad;
    slot.ad = null;
    slot.loadedAt = null;
    slot.expiry?.cancel();
    if (expired != null) _discard(expired);
    slot.loading = true;
    final generation = ++slot.generation;
    FullscreenAd? acceptedAd;
    _event('request', format);
    bool current() =>
        !_disposed && _allowed && slot.loading && slot.generation == generation;
    void failed(String reason) {
      if (!current()) return;
      slot.timeout?.cancel();
      slot.loading = false;
      _event('load_failed', format, reason: reason);
      _retry(format);
    }

    slot.timeout = Timer(loadTimeout, () => failed('load_timeout'));
    try {
      backend
          .load(format, (ad) {
            // A duplicate success must not dispose the same accepted object
            // after it has moved out of the cache into a native fullscreen.
            // Compare native ads, not wrappers: the Google adapter wraps
            // every callback in a fresh object.
            if (identical(acceptedAd?.identity, ad.identity)) return;
            if (!current()) {
              _discard(ad);
              return;
            }
            acceptedAd = ad;
            slot.timeout?.cancel();
            slot.loading = false;
            slot.failures = 0;
            slot.ad = ad;
            slot.loadedAt = nowUtc();
            _event('loaded', format);
            if (_foreground) _scheduleExpiry(format);
          }, () => failed('sdk_load_failed'))
          .catchError((Object _) => failed('load_exception'));
    } catch (_) {
      failed('load_exception');
    }
  }

  void _scheduleExpiry(AdFormat format) {
    final slot = _slots[format]!;
    slot.expiry?.cancel();
    if (slot.loadedAt == null) return;
    final remaining = cacheLifetime - nowUtc().difference(slot.loadedAt!);
    slot.expiry = Timer(
      remaining > Duration.zero ? remaining : Duration.zero,
      () => _load(format),
    );
  }

  void _retry(AdFormat format, {bool newFailure = true}) {
    final slot = _slots[format]!;
    if (newFailure) slot.failures++;
    if (!_foreground || _disposed || !_allowed || slot.retry != null) return;
    final seconds = 1 << slot.failures.clamp(1, 6);
    slot.retry = Timer(Duration(seconds: seconds), () {
      slot.retry = null;
      _load(format);
    });
  }

  @override
  void setForeground(bool value) {
    if (_disposed || value == _foreground) return;
    _foreground = value;
    for (final format in AdFormat.values) {
      final slot = _slots[format]!;
      if (!value) {
        slot.retry?.cancel();
        slot.retry = null;
        slot.expiry?.cancel();
      } else if (_valid(slot)) {
        _scheduleExpiry(format);
      } else if (slot.failures > 0 && !slot.loading) {
        _retry(format, newFailure: false);
      } else {
        _load(format);
      }
    }
    if (value) _retryConsentOnResume();
    // Resume only preloads; never displays.
  }

  String? _commonSkip(AdFormat format) {
    if (_disposed) return 'disposed';
    if (!_foreground) return 'background';
    if (!_allowed) return 'consent_or_initialization';
    if (_fullscreen) return 'fullscreen_busy';
    if (!_valid(_slots[format]!)) return 'not_ready';
    return null;
  }

  @override
  Future<void> showInterstitial({
    required VoidCallback onDismissed,
    InterstitialPlacement placement = InterstitialPlacement.afterAnalysis,
  }) async {
    try {
      final reason =
          _commonSkip(AdFormat.interstitial) ??
          policy.skipReason(nowLocal(), nowUtc());
      if (reason != null) {
        _event(
          'skipped',
          AdFormat.interstitial,
          placement: placement.name,
          reason: reason,
        );
        preloadInterstitial();
        return;
      }
      await _show(AdFormat.interstitial, placement.name, null);
    } finally {
      onDismissed();
    }
  }

  @override
  Future<AdOutcome> showRewarded({
    required Future<void> Function() onEarnedReward,
    String placement = 'reading',
  }) async {
    final reason = _commonSkip(AdFormat.rewarded);
    if (reason != null) {
      _event(
        'skipped',
        AdFormat.rewarded,
        placement: placement,
        reason: reason,
      );
      preloadRewarded();
      return AdOutcome.skipped;
    }
    return _show(AdFormat.rewarded, placement, onEarnedReward);
  }

  Future<AdOutcome> _show(
    AdFormat format,
    String placement,
    Future<void> Function()? reward,
  ) async {
    _fullscreen = true;
    final slot = _slots[format]!;
    final ad = slot.ad!;
    slot.ad = null;
    slot.loadedAt = null;
    slot.expiry?.cancel();
    final done = Completer<AdOutcome>();
    bool ended = false,
        earned = false,
        saveFailed = false,
        rewardSeen = false,
        impressed = false,
        paidReported = false;
    Future<void>? rewardSave;
    Future<void> finish(bool failed) async {
      if (ended) return;
      ended = true;
      if (!failed && format == AdFormat.interstitial)
        await policy.markDismissed(nowUtc());
      if (rewardSave != null) await rewardSave;
      _discard(ad);
      _fullscreen = false;
      _event(
        failed ? 'show_failed' : 'dismissed',
        format,
        placement: placement,
      );
      _load(format);
      done.complete(
        earned
            ? AdOutcome.rewarded
            : saveFailed
            ? AdOutcome.rewardSaveFailed
            : failed
            ? AdOutcome.failed
            : AdOutcome.dismissed,
      );
    }

    void earn() {
      if (rewardSeen || ended || reward == null) return;
      rewardSeen = true;
      earned = true;
      rewardSave = Future<void>.sync(reward).catchError((Object _) {
        earned = false;
        saveFailed = true;
        _event('reward_save_failed', format, placement: placement);
      });
    }

    _event('show_requested', format, placement: placement);
    try {
      ad
          .show(
            onDismissed: () => unawaited(finish(false)),
            onFailed: () => unawaited(finish(true)),
            onReward: earn,
            onImpression: () {
              if (!impressed && !ended) {
                impressed = true;
                _event('impression', format, placement: placement);
              }
            },
            onClick: () {
              if (!ended) _event('clicked', format, placement: placement);
            },
            onPaid: (value, currency, precision) {
              // Revenue can be delivered late. It cannot navigate or reward,
              // and must not be lost solely because dismissal arrived first.
              if (!paidReported) {
                paidReported = true;
                _event(
                  'paid',
                  format,
                  placement: placement,
                  value: value,
                  currency: currency,
                  precision: precision,
                );
              }
            },
          )
          .catchError((Object _) => unawaited(finish(true)));
    } catch (_) {
      unawaited(finish(true));
    }
    // No duration watchdog: 8 seconds is NOT a native dismissal.
    return done.future;
  }

  void _clearSlots() {
    for (final slot in _slots.values) {
      slot.generation++;
      slot.loading = false;
      slot.timeout?.cancel();
      slot.retry?.cancel();
      slot.expiry?.cancel();
      slot.retry = null;
      if (slot.ad != null) _discard(slot.ad!);
      slot.ad = null;
      slot.loadedAt = null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _allowed = false;
    _clearSlots();
  }
}
