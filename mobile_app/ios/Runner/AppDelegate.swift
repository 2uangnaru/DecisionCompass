import Flutter
import UIKit
import StoreKit
import AppTrackingTransparency
import SafariServices

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var iosChannel: FlutterMethodChannel?
  private var trackingRequestInFlight = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "astracue/ios", binaryMessenger: engineBridge.applicationRegistrar.messenger())
    iosChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(nil); return }
      switch call.method {
      case "syncPurchases":
        Task { @MainActor in
          do {
            try await AppStore.sync()
            result(nil)
          } catch {
            result(FlutterError(code: "purchase_sync_failed", message: nil, details: nil))
          }
        }
      case "verifyPlusPurchase":
        guard let args = call.arguments as? [String: Any],
              let productID = args["productId"] as? String,
              let purchaseID = args["purchaseId"] as? String else {
          result(FlutterError(code: "invalid_purchase_request", message: nil, details: nil))
          return
        }
        Task { @MainActor in
          result(await self.verifyPurchase(productID: productID, purchaseID: purchaseID))
        }
      case "requestTracking":
        self.requestTracking(result)
      case "trackingStatus":
        result(self.trackingStatus(ATTrackingManager.trackingAuthorizationStatus))
      case "openWebPage":
        guard let args = call.arguments as? [String: Any],
              let value = args["url"] as? String, let url = URL(string: value),
              url.scheme == "https", url.host != nil,
              let controller = self.visibleController() else {
          result(FlutterError(code: "web_page_unavailable", message: nil, details: nil))
          return
        }
        controller.present(SFSafariViewController(url: url), animated: true)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// No network verifier, hardcoded success or unverified receipt is used.
  /// StoreKit's signed verification result is the authority for this device.
  @MainActor
  private func verifyPurchase(productID: String, purchaseID: String) async -> [String: String] {
    var response = ["status": "unavailable", "productId": productID, "purchaseId": purchaseID]
    let configured = Bundle.main.object(forInfoDictionaryKey: "AstraCuePlusProductID") as? String
    guard !productID.isEmpty, productID == configured, UInt64(purchaseID) != nil else {
      response["status"] = "invalid"
      return response
    }
    guard let verification = await StoreKit.Transaction.latest(for: productID) else { return response }
    switch verification {
    case .unverified:
      response["status"] = "invalid"
    case .verified(let transaction):
      guard transaction.productID == productID,
            String(transaction.id) == purchaseID,
            transaction.productType == .nonConsumable else {
        response["status"] = "invalid"
        return response
      }
      #if !DEBUG
      if #available(iOS 16.0, *), transaction.environment == .xcode {
        response["status"] = "invalid"
        return response
      }
      #endif
      response["status"] = transaction.revocationDate == nil ? "valid" : "revoked"
    }
    // The Flutter store adapter alone finishes the original transaction after
    // verification. Never finish/consume here or grant from a purchase tap.
    return response
  }

  private func requestTracking(_ result: @escaping FlutterResult) {
    guard UIApplication.shared.applicationState == .active,
          !trackingRequestInFlight else { result("unavailable"); return }
    guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
      result(trackingStatus(ATTrackingManager.trackingAuthorizationStatus))
      return
    }
    trackingRequestInFlight = true
    ATTrackingManager.requestTrackingAuthorization { [weak self] status in
      DispatchQueue.main.async {
        self?.trackingRequestInFlight = false
        result(self?.trackingStatus(status) ?? "unavailable")
      }
    }
  }

  private func trackingStatus(_ status: ATTrackingManager.AuthorizationStatus) -> String {
    switch status {
    case .authorized: return "authorized"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "notDetermined"
    @unknown default: return "unavailable"
    }
  }

  private func visibleController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    var controller = scenes.flatMap { $0.windows }.first(where: { $0.isKeyWindow })?.rootViewController
    while let presented = controller?.presentedViewController { controller = presented }
    return controller
  }
}
