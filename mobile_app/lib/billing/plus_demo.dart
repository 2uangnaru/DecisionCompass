import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'plus_billing.dart';

/// Demo billing for owner previews before any store account exists.
///
/// Only a DEBUG build started with `--dart-define=PLUS_DEMO_BILLING=true`
/// uses it. A release build can never: [kDebugMode] is a compile-time false
/// there, so this path is not even compiled in.
bool plusDemoBillingEnabled({
  bool debug = kDebugMode,
  bool requested = const bool.fromEnvironment('PLUS_DEMO_BILLING'),
}) => debug && requested;

/// Proofs from the demo store carry this source; nothing else accepts it.
const plusDemoSource = 'astracue_demo';

/// Stands in for Play Billing: Buy "purchases" after a short pause, Restore
/// finds a demo purchase made earlier on this install. No money, no network.
class DemoPlusStore implements PlusStore {
  DemoPlusStore({this.delay = const Duration(milliseconds: 600)});

  final Duration delay;
  static const ownedKey = 'plus_demo_owned_v1';
  final _updates = StreamController<List<PlusPurchaseUpdate>>.broadcast();

  @override
  Stream<List<PlusPurchaseUpdate>> get updates => _updates.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PlusProduct?> queryProduct(String productId) async => PlusProduct(
    id: productId,
    price: '',
    currencyCode: '',
    rawPrice: 0,
    isPreview: true,
  );

  PlusPurchaseUpdate _owned(String productId, PlusPurchaseStatus status) =>
      PlusPurchaseUpdate(
        productId: productId,
        status: status,
        proof: PlusPurchaseProof(
          productId: productId,
          purchaseId: 'demo-$productId',
          serverVerificationData: 'demo-$productId',
          source: plusDemoSource,
        ),
      );

  @override
  Future<bool> buy(PlusProduct product) async {
    unawaited(
      Future<void>.delayed(delay, () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(ownedKey, true);
        _updates.add([_owned(product.id, PlusPurchaseStatus.purchased)]);
      }),
    );
    return true;
  }

  @override
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(ownedKey) ?? false) {
      _updates.add([
        _owned(PlusBillingConfig.defaultProductId, PlusPurchaseStatus.restored),
      ]);
    }
  }

  @override
  Future<bool> complete(PlusPurchaseUpdate update) async => true;
}

/// Accepts demo proofs only; a real store receipt is never "valid" here.
class DemoPlusVerifier implements PlusPurchaseVerifier {
  const DemoPlusVerifier();
  @override
  bool get isConfigured => true;
  @override
  Future<PlusVerdict> verify(PlusPurchaseProof proof) async =>
      proof.source == plusDemoSource ? PlusVerdict.valid : PlusVerdict.invalid;
}
