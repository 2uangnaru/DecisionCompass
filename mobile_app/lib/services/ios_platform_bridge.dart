import 'package:flutter/services.dart';

/// Small native boundary. Responses contain status/IDs, never receipts or logs.
class IOSPlatformBridge {
  const IOSPlatformBridge({this.channel = const MethodChannel('astracue/ios')});
  final MethodChannel channel;

  Future<Map<Object?, Object?>?> verifyPurchase({
    required String productId,
    required String purchaseId,
  }) => channel.invokeMapMethod<Object?, Object?>('verifyPlusPurchase', {
    'productId': productId,
    'purchaseId': purchaseId,
  });

  Future<String?> requestTracking() =>
      channel.invokeMethod<String>('requestTracking');

  Future<String?> trackingStatus() =>
      channel.invokeMethod<String>('trackingStatus');

  /// Explicit Restore only: Apple may request authentication during sync.
  Future<void> synchronizePurchases() =>
      channel.invokeMethod<void>('syncPurchases');

  Future<void> openWebPage(Uri uri) =>
      channel.invokeMethod<void>('openWebPage', {'url': uri.toString()});
}
