import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart'
    show InAppPurchasePlatform;

import '../services/ios_platform_bridge.dart';

/// Build-time Plus configuration. Nothing here is a credential.
class PlusBillingConfig {
  const PlusBillingConfig({required this.productId});

  /// `--dart-define=PLUS_PRODUCT_ID=...`: the one-time, non-consumable
  /// product configured in Play Console. The default is a placeholder.
  static const defaultProductId = String.fromEnvironment(
    'PLUS_PRODUCT_ID',
    defaultValue: 'astracue_plus_lifetime',
  );

  static PlusBillingConfig fromEnvironment() {
    const iosProduct = String.fromEnvironment('IOS_PLUS_PRODUCT_ID');
    return PlusBillingConfig(
      productId:
          !kIsWeb &&
              defaultTargetPlatform == TargetPlatform.iOS &&
              iosProduct.isNotEmpty
          ? iosProduct
          : defaultProductId,
    );
  }

  final String productId;
}

/// Store product information. [price] is the store's own formatted string;
/// the app never derives a price from language or country.
@immutable
class PlusProduct {
  const PlusProduct({
    required this.id,
    required this.price,
    required this.currencyCode,
    required this.rawPrice,
    this.referencePrice,
    this.native,
    this.isPreview = false,
  });

  final String id;
  final String price;
  final String currencyCode;
  final double rawPrice;

  /// A genuine store-provided pre-discount price. The Flutter plugin exposes
  /// none for one-time products, so this is null for real products.
  final String? referencePrice;
  final Object? native;

  /// Demo billing: no store price exists, so the paywall keeps its approved
  /// preview prices.
  final bool isPreview;
}

enum PlusPurchaseStatus { pending, purchased, restored, canceled, error }

/// A store error normalized at the adapter, so no raw platform text reaches
/// the controller, logs or analytics.
enum PlusStoreError {
  /// Android `BillingResponse.itemAlreadyOwned`: owned but not (yet) granted
  /// here. Recovered through an owned-purchases query + verification.
  alreadyOwned,
  other,
}

/// What a verifier needs to judge a purchase; persisted after verification so
/// a later reconciliation can recheck it.
@immutable
class PlusPurchaseProof {
  const PlusPurchaseProof({
    required this.productId,
    required this.purchaseId,
    required this.serverVerificationData,
    required this.source,
  });

  final String productId;
  final String? purchaseId;
  final String serverVerificationData;
  final String source;

  Map<String, Object?> toJson() => {
    'productId': productId,
    'purchaseId': purchaseId,
    'serverVerificationData': serverVerificationData,
    'source': source,
  };

  static PlusPurchaseProof? fromJson(Object? json) {
    if (json is! Map) return null;
    final product = json['productId'];
    final data = json['serverVerificationData'];
    final source = json['source'];
    final id = json['purchaseId'];
    if (product is! String || data is! String || source is! String) {
      return null;
    }
    return PlusPurchaseProof(
      productId: product,
      purchaseId: id is String ? id : null,
      serverVerificationData: data,
      source: source,
    );
  }
}

@immutable
class PlusPurchaseUpdate {
  const PlusPurchaseUpdate({
    required this.productId,
    required this.status,
    this.proof,
    this.error,
    this.needsCompletion = false,
    this.native,
  });

  final String productId;
  final PlusPurchaseStatus status;
  final PlusPurchaseProof? proof;
  final PlusStoreError? error;

  /// The store still waits for acknowledgement (Android) / finish (iOS).
  final bool needsCompletion;
  final Object? native;

  /// A stable key for de-duplicating repeated callbacks.
  String get dedupeKey =>
      proof?.purchaseId ?? proof?.serverVerificationData ?? productId;
}

/// Billing boundary. Production uses [InAppPurchasePlusStore]; tests inject
/// a fake. Nothing behind it may grant Plus by itself.
abstract interface class PlusStore {
  Stream<List<PlusPurchaseUpdate>> get updates;
  Future<bool> isAvailable();

  /// Null when the store does not know the product.
  Future<PlusProduct?> queryProduct(String productId);

  /// True when the store's checkout UI was launched. Never a purchase.
  Future<bool> buy(PlusProduct product);
  Future<void> restore();

  /// Acknowledges a non-consumable. Never consumes it. True only when the
  /// store accepted the acknowledgement; false (or a throw) leaves it for a
  /// later reconciliation to retry.
  Future<bool> complete(PlusPurchaseUpdate update);
}

abstract interface class PlusPurchaseSynchronizer {
  bool get requiresSynchronization;
  Future<void> synchronizePurchases();
}

class InAppPurchasePlusStore implements PlusStore, PlusPurchaseSynchronizer {
  InAppPurchasePlusStore([InAppPurchase? iap])
    : _iap = iap ?? InAppPurchase.instance;
  final InAppPurchase _iap;

  @override
  bool get requiresSynchronization =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Stream<List<PlusPurchaseUpdate>> get updates => _iap.purchaseStream.map(
    (list) => [for (final details in list) map(details)],
  );

  /// Android reports a failed launch as `IAPError(code: 'purchase_error',
  /// message: BillingResponse.<name>)`, and when Play returns no purchase
  /// list it emits a `PurchaseDetails` whose `productID` is empty.
  @visibleForTesting
  static PlusStoreError? normalizeError(IAPError? error) {
    if (error == null) return null;
    if (error.message == BillingResponse.itemAlreadyOwned.toString()) {
      return PlusStoreError.alreadyOwned;
    }
    return PlusStoreError.other;
  }

  /// `completePurchase` on Android answers with a [BillingResultWrapper]
  /// instead of throwing; anything but `ok` is a failed acknowledgement.
  @visibleForTesting
  static bool acknowledged(Object? result) =>
      result is! BillingResultWrapper ||
      result.responseCode == BillingResponse.ok;

  @visibleForTesting
  static PlusPurchaseUpdate map(PurchaseDetails d) => PlusPurchaseUpdate(
    productId: d.productID,
    // Android's restore relabels every listed purchase "restored", including
    // payments still pending; those must never be verified or acknowledged.
    status:
        d is GooglePlayPurchaseDetails &&
            d.billingClientPurchase.purchaseState ==
                PurchaseStateWrapper.pending
        ? PlusPurchaseStatus.pending
        : switch (d.status) {
            PurchaseStatus.pending => PlusPurchaseStatus.pending,
            PurchaseStatus.purchased => PlusPurchaseStatus.purchased,
            PurchaseStatus.restored => PlusPurchaseStatus.restored,
            PurchaseStatus.canceled => PlusPurchaseStatus.canceled,
            PurchaseStatus.error => PlusPurchaseStatus.error,
          },
    proof: d.verificationData.serverVerificationData.isEmpty
        ? null
        : PlusPurchaseProof(
            productId: d.productID,
            purchaseId: d.purchaseID,
            serverVerificationData: d.verificationData.serverVerificationData,
            source: d.verificationData.source,
          ),
    error: normalizeError(d.error),
    needsCompletion: d.pendingCompletePurchase,
    native: d,
  );

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<PlusProduct?> queryProduct(String productId) async {
    final response = await _iap.queryProductDetails({productId});
    if (response.error != null) {
      throw StateError('plus_product_query_failed');
    }
    for (final p in response.productDetails) {
      if (p.id != productId) continue;
      return PlusProduct(
        id: p.id,
        price: p.price,
        currencyCode: p.currencyCode,
        rawPrice: p.rawPrice,
        native: p,
      );
    }
    return null;
  }

  @override
  Future<bool> buy(PlusProduct product) => _iap.buyNonConsumable(
    purchaseParam: PurchaseParam(
      productDetails: product.native! as ProductDetails,
    ),
  );

  @override
  Future<void> restore() => _iap.restorePurchases();

  @override
  Future<void> synchronizePurchases() async {
    if (requiresSynchronization) {
      await const IOSPlatformBridge().synchronizePurchases();
    }
  }

  @override
  Future<bool> complete(PlusPurchaseUpdate update) async {
    final details = update.native! as PurchaseDetails;
    final platform = InAppPurchasePlatform.instance;
    // The app-facing API drops Android's BillingResult; ask the platform.
    if (platform is InAppPurchaseAndroidPlatform) {
      return acknowledged(await platform.completePurchase(details));
    }
    await _iap.completePurchase(details);
    return true;
  }
}

/// [valid]: grant. [invalid]: never grant. [revoked]: an authoritative
/// refund/revocation. [unavailable]: no answer (offline, not configured,
/// server error) — grants nothing new and revokes nothing.
enum PlusVerdict { valid, invalid, revoked, unavailable }

abstract interface class PlusPurchaseVerifier {
  bool get isConfigured;
  Future<PlusVerdict> verify(PlusPurchaseProof proof);
}

/// No verifier has been configured: everything is [PlusVerdict.unavailable].
class UnconfiguredPlusVerifier implements PlusPurchaseVerifier {
  const UnconfiguredPlusVerifier();
  @override
  bool get isConfigured => false;
  @override
  Future<PlusVerdict> verify(PlusPurchaseProof proof) async =>
      PlusVerdict.unavailable;
}

/// Apple verifies StoreKit 2 transactions on-device. The native handler looks
/// up the transaction itself; it does not trust a Dart flag or decode-only JWS.
class IOSStoreKitPlusVerifier implements PlusPurchaseVerifier {
  const IOSStoreKitPlusVerifier({
    required this.productId,
    this.bridge = const IOSPlatformBridge(),
  });
  final String productId;
  final IOSPlatformBridge bridge;

  @override
  bool get isConfigured => true;

  @override
  Future<PlusVerdict> verify(PlusPurchaseProof proof) async {
    final id = proof.purchaseId;
    if (proof.source != 'app_store' ||
        proof.productId != productId ||
        id == null ||
        !RegExp(r'^\d+$').hasMatch(id)) {
      return PlusVerdict.invalid;
    }
    try {
      final response = await bridge
          .verifyPurchase(productId: productId, purchaseId: id)
          .timeout(const Duration(seconds: 15));
      if (response == null ||
          response['productId'] != productId ||
          response['purchaseId'] != id)
        return PlusVerdict.unavailable;
      return switch (response['status']) {
        'valid' => PlusVerdict.valid,
        'revoked' => PlusVerdict.revoked,
        'invalid' => PlusVerdict.invalid,
        _ => PlusVerdict.unavailable,
      };
    } catch (_) {
      // Missing channel, native failure and timeout never grant or revoke.
      return PlusVerdict.unavailable;
    }
  }
}

/// Android remains fail-closed until its server verifier is configured.
PlusPurchaseVerifier plusVerifierFor(PlusBillingConfig config) =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
    ? IOSStoreKitPlusVerifier(productId: config.productId)
    : const UnconfiguredPlusVerifier();
