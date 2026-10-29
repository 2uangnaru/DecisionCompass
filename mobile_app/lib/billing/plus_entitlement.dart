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

/// One owned-purchases query and the verdicts its purchases received.
/// Startup, resume and Restore share a running one instead of racing.
class _Reconcile {
  final verdicts = <PlusVerdict>[];
  bool failed = false;
}

/// Owns the Plus purchase lifecycle and the persisted, verified entitlement.
///
/// Policy: only a [PlusVerdict.valid] verification grants. A previously
/// verified entitlement survives offline starts, verifier failures/timeouts
/// and failed or empty queries; only an authoritative [PlusVerdict.revoked]
/// removes it. The local record is not tamper-proof (see `PLUS_BILLING.md`).
///
/// Every store and verifier call is bounded, updates are processed in order
/// on one queue, and nothing mutates state after [dispose].
class PlusEntitlementController extends ChangeNotifier implements PlusAccess {
  PlusEntitlementController({
    required this.store,
    required this.verifier,
    required this.productId,
    this.ads,
    this.requireSupportedSaleClaims = true,
    this.acceptDemoProofs = false,
    this.verifyTimeout = const Duration(seconds: 20),
    this.storeTimeout = const Duration(seconds: 20),
    this.resumeRetryInterval = const Duration(minutes: 1),
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

  /// Bounds on one verification and one store call. A timed-out answer is
  /// [PlusVerdict.unavailable] or a failure, and its late result is ignored.
  final Duration verifyTimeout;
  final Duration storeTimeout;

  /// Minimum spacing of automatic retries started by an app resume.
  final Duration resumeRetryInterval;
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

  /// Purchases whose benefits were delivered this session (idempotency).
  final _granted = <String>{};

  /// An acknowledgement failed and waits for a reconciliation retry.
  bool _ackPending = false;
  DateTime? _lastCatalogAttempt;
  DateTime? _lastReconcileAttempt;
  Future<void>? _catalogRefresh;
  Future<_Reconcile>? _reconcileRun;
  _Reconcile? _currentReconcile;
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

  /// An acknowledgement is waiting for the next reconciliation.
  bool get acknowledgementPending => _ackPending;

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
      if (raw != null && !_disposed) {
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

  /// Subscribes once, then discovers the store and reconciles ownership.
  /// Never shows any UI.
  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    await loadCached();
    if (_disposed) return;
    _subscription = store.updates.listen((updates) {
      for (final update in updates) {
        _enqueue(() => _handle(update));
      }
    }, onError: (Object _) {});
    await refreshStore();
    if (_disposed) return;
    await _recheckCachedProof();
    if (_disposed) return;
    // Always, even with cached Plus: recovers purchases completed while the
    // app was killed, retries acknowledgements and revalidates ownership.
    await _reconcileOwned();
  }

  /// Re-discovers availability and the product. Concurrent callers share one
  /// attempt; a failed query keeps the last genuine product.
  Future<void> refreshStore() {
    if (_disposed) return Future<void>.value();
    return _catalogRefresh ??= _refreshCatalog().whenComplete(
      () => _catalogRefresh = null,
    );
  }

  Future<void> _refreshCatalog() async {
    _lastCatalogAttempt = _nowUtc();
    var available = false;
    try {
      available = await store.isAvailable().timeout(storeTimeout);
    } catch (_) {}
    if (_disposed) return;
    var product = _product;
    if (available) {
      try {
        product = await store.queryProduct(productId).timeout(storeTimeout);
      } catch (_) {
        // Keep the last genuine product; nothing is invented.
      }
      if (_disposed) return;
    }
    _storeAvailable = available;
    _product = product;
    _notify();
  }

  /// Launches checkout. True only means the store sheet opened.
  Future<bool> buy() async {
    var reason = checkoutBlockReason;
    if (reason == PlusBlockReason.storeUnavailable ||
        reason == PlusBlockReason.productUnavailable) {
      // An explicit tap is a fair moment to retry discovery once.
      await refreshStore();
      if (_disposed) return false;
      reason = checkoutBlockReason;
    }
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
      launched = await store.buy(_product!).timeout(storeTimeout);
    } catch (_) {
      launched = false;
    }
    if (_disposed) return false;
    if (!launched && _checkout == PlusCheckoutState.purchasing) {
      _endCheckout(PlusPurchaseOutcome.failed);
      _notify();
    }
    return launched;
  }

  /// Restores through the store account and revalidates what it returns,
  /// including purchases already granted. Grants only verified purchases.
  Future<PlusRestoreResult> restore() async {
    if (_disposed) return PlusRestoreResult.failed;
    if (_checkout != PlusCheckoutState.idle) {
      return _finishRestore(PlusRestoreResult.failed);
    }
    _checkout = PlusCheckoutState.restoring;
    _notify();
    if (!_storeAvailable) await refreshStore();
    if (_disposed) return PlusRestoreResult.failed;
    final run = await _reconcileOwned();
    if (_disposed) return PlusRestoreResult.failed;
    if (_checkout == PlusCheckoutState.restoring) {
      _checkout = PlusCheckoutState.idle;
    }
    final PlusRestoreResult result;
    if (run.failed) {
      result = PlusRestoreResult.failed;
    } else if (run.verdicts.contains(PlusVerdict.valid)) {
      result = PlusRestoreResult.restored;
    } else if (_active) {
      // Previously verified access the store could not reconfirm right now.
      result = PlusRestoreResult.restored;
    } else if (run.verdicts.contains(PlusVerdict.unavailable)) {
      result = PlusRestoreResult.verificationUnavailable;
    } else {
      result = PlusRestoreResult.nothingToRestore;
    }
    return _finishRestore(result);
  }

  PlusRestoreResult _finishRestore(PlusRestoreResult result) {
    _lastRestore = result;
    _notify();
    return result;
  }

  /// The store sheet closing resumes the app: free the ad guard, and retry
  /// what an earlier failure left (discovery, acknowledgement) at most once
  /// per [resumeRetryInterval]. Never shows anything.
  void appResumed() {
    if (_disposed) return;
    if (_checkout == PlusCheckoutState.purchasing) {
      _releaseGuard();
      _graceTimer?.cancel();
      _graceTimer = Timer(_checkoutGrace, () {
        if (_disposed || _checkout != PlusCheckoutState.purchasing) return;
        _endCheckout(PlusPurchaseOutcome.failed);
        _notify();
      });
    }
    if (_started) unawaited(_resumeRecovery());
  }

  bool _due(DateTime? last) =>
      last == null || _nowUtc().difference(last) >= resumeRetryInterval;

  Future<void> _resumeRecovery() async {
    if ((!_storeAvailable || _product == null) && _due(_lastCatalogAttempt)) {
      await refreshStore();
    }
    if (_disposed) return;
    if (_ackPending &&
        _checkout == PlusCheckoutState.idle &&
        _due(_lastReconcileAttempt)) {
      await _reconcileOwned();
    }
  }

  /// One owned-purchases query at a time; overlapping callers join it.
  Future<_Reconcile> _reconcileOwned() => _reconcileRun ??= _runReconcile()
      .whenComplete(() => _reconcileRun = null);

  Future<_Reconcile> _runReconcile() async {
    final run = _Reconcile();
    if (_disposed || !_storeAvailable) {
      run.failed = true;
      return run;
    }
    _lastReconcileAttempt = _nowUtc();
    _currentReconcile = run;
    try {
      await store.restore().timeout(storeTimeout);
      await _drain();
    } catch (_) {
      // A failed query revokes nothing; it is only a failed reconciliation.
      run.failed = true;
    } finally {
      if (identical(_currentReconcile, run)) _currentReconcile = null;
    }
    return run;
  }

  /// Startup revalidation of the cached proof itself (covers a refunded
  /// purchase the store no longer lists). Runs on the update queue.
  Future<void> _recheckCachedProof() {
    final proof = _proof;
    if (!_active || proof == null || !verifier.isConfigured) {
      return Future<void>.value();
    }
    final done = Completer<void>();
    _enqueue(() async {
      try {
        final verdict = await _verify(proof);
        if (_disposed) return;
        if (verdict == PlusVerdict.revoked &&
            _proof?.serverVerificationData == proof.serverVerificationData) {
          await _revoke();
        }
      } finally {
        done.complete();
      }
    });
    return done.future;
  }

  /// Stream events are delivered asynchronously after the store call
  /// returns; let them land, then wait for their processing.
  Future<void> _drain() async {
    await Future<void>.delayed(Duration.zero);
    await _queue;
  }

  void _enqueue(Future<void> Function() job) {
    _queue = _queue.then((_) async {
      if (_disposed) return;
      try {
        await job();
      } catch (_) {
        // Never strand checkout on an unexpected failure.
        if (!_disposed && _checkout != PlusCheckoutState.restoring) {
          _endCheckout(PlusPurchaseOutcome.failed);
          _notify();
        }
      }
    });
  }

  Future<PlusVerdict> _verify(PlusPurchaseProof proof) async {
    try {
      return await verifier.verify(proof).timeout(verifyTimeout);
    } catch (_) {
      // Thrown or timed out: no answer. A late result is never applied.
      return PlusVerdict.unavailable;
    }
  }

  Future<void> _handle(PlusPurchaseUpdate update) async {
    if (_disposed) return;
    if (update.productId.isEmpty) {
      _handleAnonymous(update);
      _notify();
      return;
    }
    if (update.productId != productId) return;
    final checkoutResult =
        update.status != PlusPurchaseStatus.restored &&
        (_checkout == PlusCheckoutState.purchasing ||
            _checkout == PlusCheckoutState.pending);
    if (checkoutResult) {
      _graceTimer?.cancel();
      _releaseGuard();
    }
    switch (update.status) {
      case PlusPurchaseStatus.pending:
        if (!_active && checkoutResult) {
          _checkout = PlusCheckoutState.pending;
          _lastOutcome = PlusPurchaseOutcome.pending;
        }
      case PlusPurchaseStatus.canceled:
        if (checkoutResult) _endCheckout(PlusPurchaseOutcome.canceled);
        await _acknowledge(update);
      case PlusPurchaseStatus.error:
        if (checkoutResult) _endCheckout(PlusPurchaseOutcome.failed);
        await _acknowledge(update);
        if (update.error == PlusStoreError.alreadyOwned) _recoverOwned();
      case PlusPurchaseStatus.purchased:
        await _deliver(update, revalidate: false);
      case PlusPurchaseStatus.restored:
        await _deliver(update, revalidate: true);
    }
    _notify();
  }

  /// Android sends `productID: ''` when Play returns no purchase list. Only
  /// a cancel/error for the checkout this controller launched is settled by
  /// it; anything else is ambiguous and ignored. It never grants.
  void _handleAnonymous(PlusPurchaseUpdate update) {
    if (_checkout != PlusCheckoutState.purchasing) return;
    switch (update.status) {
      case PlusPurchaseStatus.canceled:
        _graceTimer?.cancel();
        _endCheckout(PlusPurchaseOutcome.canceled);
      case PlusPurchaseStatus.error:
        _graceTimer?.cancel();
        _endCheckout(PlusPurchaseOutcome.failed);
        if (update.error == PlusStoreError.alreadyOwned) _recoverOwned();
      case PlusPurchaseStatus.pending:
      case PlusPurchaseStatus.purchased:
      case PlusPurchaseStatus.restored:
        break;
    }
  }

  /// Owned but not granted here: query ownership; the result is verified as
  /// usual. Not awaited, since this runs on the queue the query drains.
  void _recoverOwned() => unawaited(_reconcileOwned());

  /// Delivery is idempotent; revalidation is not skipped for restored
  /// purchases, so an explicit Restore or reconciliation rechecks even a
  /// purchase already granted.
  Future<void> _deliver(
    PlusPurchaseUpdate update, {
    required bool revalidate,
  }) async {
    final run = _currentReconcile;
    final proof = update.proof;
    if (proof == null) {
      run?.verdicts.add(PlusVerdict.invalid);
      if (!revalidate) _endCheckout(PlusPurchaseOutcome.invalid);
      return;
    }
    final delivered =
        _active &&
        (_granted.contains(update.dedupeKey) ||
            _proof?.serverVerificationData == proof.serverVerificationData);
    if (delivered && !revalidate) {
      // An ordinary duplicate callback: nothing is delivered again, but the
      // store may still be waiting for its acknowledgement.
      await _acknowledge(update);
      return;
    }
    if (!revalidate && _checkout != PlusCheckoutState.restoring) {
      _checkout = PlusCheckoutState.verifying;
      _notify();
    }
    final verdict = await _verify(proof);
    if (_disposed) return;
    run?.verdicts.add(verdict);
    switch (verdict) {
      case PlusVerdict.valid:
        _granted.add(update.dedupeKey);
        if (!delivered) {
          _proof = proof;
          _setActive(true);
          await _persist();
          if (_disposed) return;
        }
        await _acknowledge(update);
        if (!revalidate) _endCheckout(PlusPurchaseOutcome.verified);
      case PlusVerdict.revoked:
        if (_active &&
            _proof?.serverVerificationData == proof.serverVerificationData) {
          await _revoke();
        }
        if (!revalidate) _endCheckout(PlusPurchaseOutcome.invalid);
      case PlusVerdict.invalid:
        // Not acknowledged: Play refunds an unacknowledged purchase.
        if (!revalidate) _endCheckout(PlusPurchaseOutcome.invalid);
      case PlusVerdict.unavailable:
        // Nothing new is granted or acknowledged; the store redelivers it.
        // A purchase verified earlier may still be acknowledged.
        if (delivered) await _acknowledge(update);
        if (!revalidate) {
          _endCheckout(PlusPurchaseOutcome.verificationUnavailable);
        }
    }
  }

  /// Leaves purchasing / pending / verifying for idle; Restore keeps its
  /// own state until it finishes.
  void _endCheckout(PlusPurchaseOutcome outcome) {
    if (_checkout != PlusCheckoutState.restoring) {
      _checkout = PlusCheckoutState.idle;
    }
    _lastOutcome = outcome;
    _releaseGuard();
  }

  Future<void> _acknowledge(PlusPurchaseUpdate update) async {
    if (!update.needsCompletion) return;
    var ok = false;
    try {
      ok = await store.complete(update).timeout(storeTimeout);
    } catch (_) {
      ok = false;
    }
    if (_disposed) return;
    // A failure is retried by the next startup or resume reconciliation,
    // which lists the purchase again with its real acknowledgement state.
    _ackPending = !ok;
  }

  Future<void> _revoke() async {
    _setActive(false);
    _proof = null;
    _granted.clear();
    await _persist();
  }

  Future<void> _persist() async {
    if (_disposed) return;
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
      // In memory this session; the next start re-verifies via the query.
    }
  }

  void _setActive(bool value) {
    if (_disposed || _active == value) return;
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

  @override
  void dispose() {
    _disposed = true;
    _graceTimer?.cancel();
    _releaseGuard();
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
