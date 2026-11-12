import Flutter
import UIKit
import XCTest

class RunnerTests: XCTestCase {

  func testPrivacyDefaultsArePresentInBuiltBundle() {
    let bundle = Bundle.main
    XCTAssertFalse(bundle.object(forInfoDictionaryKey: "FIREBASE_ANALYTICS_COLLECTION_ENABLED") as? Bool ?? true)
    XCTAssertFalse(bundle.object(forInfoDictionaryKey: "GOOGLE_ANALYTICS_IDFV_COLLECTION_ENABLED") as? Bool ?? true)
    for key in ["NSUserTrackingUsageDescription", "NSLocationWhenInUseUsageDescription"] {
      let value = bundle.object(forInfoDictionaryKey: key) as? String ?? ""
      XCTAssertFalse(value.isEmpty, key)
      XCTAssertFalse(value.contains("$("), "Unresolved build setting: \(key)")
    }
    XCTAssertNotNil(bundle.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
  }

  func testPermissionPromptsHaveAllSupportedLocalizations() {
    for language in ["en", "vi", "ja", "es", "th", "hi", "zh-Hans", "ko"] {
      guard let directory = Bundle.main.path(forResource: language, ofType: "lproj"),
            let bundle = Bundle(path: directory) else {
        XCTFail("Missing native permission localization: \(language)")
        continue
      }
      for key in ["NSUserTrackingUsageDescription", "NSLocationWhenInUseUsageDescription"] {
        let prompt = bundle.localizedString(forKey: key, value: nil, table: "InfoPlist")
        XCTAssertNotEqual(prompt, key, "\(language): \(key)")
        XCTAssertFalse(prompt.isEmpty)
      }
    }
  }

}
