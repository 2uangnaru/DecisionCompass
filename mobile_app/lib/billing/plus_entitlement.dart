import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ad_runtime.dart';
import 'plus_billing.dart';
import 'plus_demo.dart' show plusDemoSource;

/// Read-only Plus state for gates. [isActive] is the app's single source of
/// truth; it only turns on after a VERIFIED purchase.
abstract interface class PlusAccess implements Listenable {
  bool get isActive;
}

enum PlusCheckoutState { idle, purchasing, pending, verifying, restoring }

/// Why [PlusEntitlementController.buy] would not launch checkout. Each has
/// no approved presentation yet; the UI only reads it.
enum PlusBlockReason {
  alreadyActive,
  inProgress,
  storeUnavailable,
  productUnavailable,
  verifierNotConfigured,

  /// The approved CTA shows a struck-through reference price and a discount
  /// badge, but the store supplies no such data for this product.
  unsupportedSaleClaims,
  fullscreenBusy,
}

enum PlusPurchaseOutcome {
  verified,
  pending,
  canceled,
  failed,
  invalid,
  verificationUnavailable,
}

enum PlusRestoreResult {
  restored,
  nothingToRestore,
  verificationUnavailable,
  failed,
}

/// Owns the Plus purchase lifecycle and the persisted, verified entitlement.
///
/// Policy: only a [PlusVerdict.valid] verification grants. A previously
/// verified entitlement survives offline starts and failed/incomplete
/// queries; only an authoritative [PlusVerdict.revoked] removes it. The local
/// record is not tamper-proof (see `PLUS_BILLING.md`).
class PlusEntitlementController extends ChangeNotifier implements PlusAccess {
  PlusEntitlementController({
    required this.store,
    required this.verifier,
    required this.productId,
    this.ads,
    this.requireSupportedSaleClaims = true,
    this.acceptDemoProofs = false,
    DateTime Function()? nowUtc,
  }) : _nowUtc = nowUtc ?? _utc;

  final PlusStore store;
  final PlusPurchaseVerifier verifier;
  final String productId;
  final AdService? ads;

  /// The approved paywall advertises a reference price and discount; while
  /// true, checkout stays blocked unless the store backs both.
  final bool requireSupportedSaleClaims;

  /// Only a demo build honours a saved demo entitlement, so a demo purchase
  /// can never carry over into a store build on the same install.
  final bool acceptDemoProofs;
  final DateTime Function() _nowUtc;
  static DateTime _utc() => DateTime.now().toUtc();

  static const storageKey = 'plus_entitlement_v1';
  static const _checkoutGrace = Duration(seconds: 10);

  bool _active = false;
  PlusPurchaseProof? _proof;
  bool _loaded = false;
  Future<void>? _loading;
  bool _started = false;
  bool _storeAvailable = false;
  PlusProduct? _product;
  PlusCheckoutState _checkout = PlusCheckoutState.idle;
  PlusPurchaseOutcome? _lastOutcome;
  PlusRestoreResult? _lastRestore;
  PlusBlockReason? _lastBlock;
  bool _holdingGuard = false;
  bool _silentRestore = false;
  final _restoreVerdicts = <PlusVerdict>[];
  final _granted = <String>{};
  StreamSubscription<List<PlusPurchaseUpdate>>? _subscription;
  Future<void> _queue = Future<void>.value();
  Timer? _graceTimer;
  bool _disposed = false;

  @override
  bool get isActive => _active;
  PlusProduct? get product => _product;
  PlusCheckoutState get checkout => _checkout;
  PlusPurchaseOutcome? get lastOutcome => _lastOutcome;
  PlusRestoreResult? get lastRestore => _lastRestore;
  PlusBlockReason? get lastBlock => _lastBlock;

  /// Null when checkout may launch now.
  PlusBlockReason? get checkoutBlockReason {
    if (_active) return PlusBlockReason.alreadyActive;
    if (_checkout != PlusCheckoutState.idle) return PlusBlockReason.inProgress;
    if (!_storeAvailable) return PlusBlockReason.storeUnavailable;
    final product = _product;
    if (product == null) return PlusBlockReason.productUnavailable;
    if (!verifier.isConfigured) return PlusBlockReason.verifierNotConfigured;
    if (requireSupportedSaleClaims && product.referencePrice == null) {
      return PlusBlockReason.unsupportedSaleClaims;
    }
    if (ads?.presentation.value.fullscreenBusy ?? false) {
      return PlusBlockReason.fullscreenBusy;
    }
    return null;
  }

  /// Reads the persisted entitlement. Local and fast: run before first frame
  /// so a Plus owner never sees an ad flash in.
  Future<void> loadCached() {
    if (_loaded) return Future<void>.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw != null) {
        final json = jsonDecode(raw);
        if (json is Map && json['active'] == true) {
          final proof = PlusPurchaseProof.fromJson(json['proof']);
          if (proof != null &&
              proof.productId == productId &&
              (acceptDemoProofs || proof.source != plusDemoSource)) {
            _proof = proof;
            _setActive(true);
          }
        }
      }
    } catch (_) {
      // Unreadable record grants nothing.
    } finally {
      _loaded = true;
      _loading = null;
    }
  }

  /// Connects to the store. Safe to call once; never shows any UI.
  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    await loadCached();
    _subscription = store.updates.listen((updates) {
      for (final update in updates) {
        _enqueue(() => _handle(update));
      }
    }, onError: (Object _) {});
    try {
      _storeAvailable = await store.isAvailable();
    } catch (_) {
      _storeAvailable = false;
    }
    if (_storeAvailable) {
      try {
        _product = await store.queryProduct(productId);
      } catch (_) {
        _product = null;
      }
    }
    _notify();
    final proof = _proof;
    if (_active && proof != null && verifier.isConfigured) {
      final verdict = await verifier.verify(proof);
      if (verdict == PlusVerdict.revoked) await _revoke();
    }
    // Restart recovery: a purchase completed while the app was killed is
    // redelivered through the owned-purchases query.
    if (!_active && _storeAvailable) {
      _silentRestore = true;
      try {
        await store.restore();
        await _drain();
      } catch (_) {
      } finally {
        _silentRestore = false;
      }
    }
  }

  /// Launches checkout. True only means the store sheet opened.
  Future<bool> buy() async {
    final reason = checkoutBlockReason;
    if (reason != null) {
      _lastBlock = reason;
      _notify();
      return false;
    }
    // Store checkout is fullscreen: no ad or consent form may sit under it.
    if (!(ads?.claimFullscreen() ?? true)) {
      _lastBlock = PlusBlockReason.fullscreenBusy;
      _notify();
      return false;
    }
    _holdingGuard = ads != null;
    _lastBlock = null;
    _lastOutcome = null;
    _checkout = PlusCheckoutState.purchasing;
    _notify();
    var launched = false;
    try {
      launched = await store.buy(_product!);
    } catch (_) {
      launched = false;
    }
    if (!launched) {
      _releaseGuard();
      _checkout = PlusCheckoutState.idle;
      _lastOutcome = PlusPurchaseOutcome.failed;
      _notify();
    }
    return launched;
  }

  /// Restores through the store account. Grants only verified purchases.
  Future<PlusRestoreResult> restore() async {
    if (_checkout != PlusCheckoutState.idle || !_storeAvailable) {
      return _finishRestore(PlusRestoreResult.failed);
    }
    _checkout = PlusCheckoutState.restoring;
    _restoreVerdicts.clear();
    _notify();
    try {
      await store.restore();
      await _drain();
    } catch (_) {
      _checkout = PlusCheckoutState.idle;
      return _finishRestore(PlusRestoreResult.failed);
    }
    _checkout = PlusCheckoutState.idle;
    final result = _restoreVerdicts.contains(PlusVerdict.valid) || _active
        ? PlusRestoreResult.restored
        : _restoreVerdicts.contains(PlusVerdict.unavailable)
        ? PlusRestoreResult.verificationUnavailable
        : PlusRestoreResult.nothingToRestore;
    return _finishRestore(result);
  }

  PlusRestoreResult _finishRestore(PlusRestoreResult result) {
    _lastRestore = result;
    _notify();
    return result;
  }

  /// The store sheet closing resumes the app. If no update follows, release
  /// the ad guard now and the checkout state after a short grace.
  void appResumed() {
    if (_checkout != PlusCheckoutState.purchasing) return;
    _releaseGuard();
    _graceTimer?.cancel();
    _graceTimer = Timer(_checkoutGrace, () {
      if (_checkout == PlusCheckoutState.purchasing) {
        _checkout = PlusCheckoutState.idle;
        _notify();
      }
    });
  }

  /// Stream events are delivered asynchronously after the store call
  /// returns; let them land, then wait for their processing.
  Future<void> _drain() async {
    await Future<void>.delayed(Duration.zero);
    await _queue;
  }

  void _enqueue(Future<void> Function() job) {
    _queue = _queue.then((_) => job()).catchError((Object _) {});
  }

  Future<void> _handle(PlusPurchaseUpdate update) async {
    if (_disposed || update.productId != productId) return;
    _graceTimer?.cancel();
    _releaseGuard();
    switch (update.status) {
      case PlusPurchaseStatus.pending:
        if (!_active) {
          _checkout = PlusCheckoutState.pending;
          _lastOutcome = PlusPurchaseOutcome.pending;
        }
      case PlusPurchaseStatus.canceled:
        _settle(PlusPurchaseOutcome.canceled);
        await _completeIfNeeded(update);
      case PlusPurchaseStatus.error:
        _settle(PlusPurchaseOutcome.failed);
        await _completeIfNeeded(update);
        if ((update.errorCode ?? '').toLowerCase().contains('alreadyowned')) {
          // Owned but never granted here (e.g. verification was down): the
          // owned-purchases query redelivers it for verification.
          _enqueue(() async {
            try {
              await store.restore();
            } catch (_) {}
          });
        }
      case PlusPurchaseStatus.purchased:
      case PlusPurchaseStatus.restored:
        await _verifyAndGrant(update);
    }
    _notify();
  }

  void _settle(PlusPurchaseOutcome outcome) {
    if (_checkout != PlusCheckoutState.restoring) {
      _checkout = PlusCheckoutState.idle;
    }
    _lastOutcome = outcome;
  }

  Future<void> _verifyAndGrant(PlusPurchaseUpdate update) async {
    final proof = update.proof;
    final restoring = _checkout == PlusCheckoutState.restoring;
    if (proof == null) {
      if (restoring) _restoreVerdicts.add(PlusVerdict.invalid);
      _settle(PlusPurchaseOutcome.invalid);
      return;
    }
    // A repeated callback for a purchase already granted only needs the
    // store's acknowledgement; it never grants or notifies twice.
    if (_active && _granted.contains(update.dedupeKey)) {
      if (restoring) _restoreVerdicts.add(PlusVerdict.valid);
      await _completeIfNeeded(update);
      return;
    }
    if (!restoring) _checkout = PlusCheckoutState.verifying;
    _notify();
    final verdict = await verifier.verify(proof);
    if (restoring) _restoreVerdicts.add(verdict);
    switch (verdict) {
      case PlusVerdict.valid:
        _granted.add(update.dedupeKey);
        _proof = proof;
        _setActive(true);
        await _persist();
        await _completeIfNeeded(update);
        _settle(PlusPurchaseOutcome.verified);
      case PlusVerdict.revoked:
        if (_active &&
            _proof?.serverVerificationData == proof.serverVerificationData) {
          await _revoke();
        }
        _settle(PlusPurchaseOutcome.invalid);
      case PlusVerdict.invalid:
        // Not acknowledged: Play refunds an unacknowledged purchase.
        _settle(PlusPurchaseOutcome.invalid);
      case PlusVerdict.unavailable:
        // Not acknowledged either, so the store redelivers it later.
        _settle(PlusPurchaseOutcome.verificationUnavailable);
    }
  }

  Future<void> _completeIfNeeded(PlusPurchaseUpdate update) async {
    if (!update.needsCompletion) return;
    try {
      await store.complete(update);
    } catch (_) {
      // Retried when the store redelivers the purchase.
    }
  }

  Future<void> _revoke() async {
    _setActive(false);
    _proof = null;
    _granted.clear();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        storageKey,
        jsonEncode({
          'active': _active,
          'proof': _proof?.toJson(),
          'updatedAtMs': _nowUtc().millisecondsSinceEpoch,
        }),
      );
    } catch (_) {
      // In memory this session; the next start re-verifies via restore.
    }
  }

  void _setActive(bool value) {
    if (_active == value) return;
    _active = value;
    ads?.setAdFree(value);
    _notify();
  }

  void _releaseGuard() {
    if (!_holdingGuard) return;
    _holdingGuard = false;
    ads?.releaseFullscreen();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Silent startup reconciliation must not report a restore result.
  @visibleForTesting
  bool get reconciling => _silentRestore;

  @override
  void dispose() {
    _disposed = true;
    _graceTimer?.cancel();
    _releaseGuard();
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
