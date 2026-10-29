import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Build-time Plus configuration. Nothing here is a credential.
class PlusBillingConfig {
  const PlusBillingConfig({required this.productId});

  /// `--dart-define=PLUS_PRODUCT_ID=...`: the one-time, non-consumable
  /// product configured in Play Console. The default is a placeholder.
  static const defaultProductId = String.fromEnvironment(
    'PLUS_PRODUCT_ID',
    defaultValue: 'astracue_plus_lifetime',
  );

  static PlusBillingConfig fromEnvironment() =>
      const PlusBillingConfig(productId: defaultProductId);

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
    this.errorCode,
    this.needsCompletion = false,
    this.native,
  });

  final String productId;
  final PlusPurchaseStatus status;
  final PlusPurchaseProof? proof;
  final String? errorCode;

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

  /// Acknowledges a non-consumable. Never consumes it.
  Future<void> complete(PlusPurchaseUpdate update);
}

class InAppPurchasePlusStore implements PlusStore {
  InAppPurchasePlusStore([InAppPurchase? iap])
    : _iap = iap ?? InAppPurchase.instance;
  final InAppPurchase _iap;

  @override
  Stream<List<PlusPurchaseUpdate>> get updates => _iap.purchaseStream.map(
    (list) => [for (final details in list) _map(details)],
  );

  static PlusPurchaseUpdate _map(PurchaseDetails d) => PlusPurchaseUpdate(
    productId: d.productID,
    status: switch (d.status) {
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
    errorCode: d.error?.code,
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
  Future<void> complete(PlusPurchaseUpdate update) =>
      _iap.completePurchase(update.native! as PurchaseDetails);
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

/// Production verifier: none exists yet, so activation stays fail-closed.
/// A server adapter implementing the contract in `PLUS_BILLING.md` replaces
/// this once the owner deploys one (the offline-guarantee test then needs a
/// deliberate update, since it forbids HTTP in the production graph).
PlusPurchaseVerifier plusVerifierFor(PlusBillingConfig config) =>
    const UnconfiguredPlusVerifier();
