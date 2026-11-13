#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(uname -s)" != Darwin ]]; then
  echo "iOS builds require macOS and Xcode." >&2
  exit 1
fi
export BYPASS_PERMISSION_LOCATION_ALWAYS=1
if [[ "${1:-}" == --demo ]]; then
  flutter build ios --debug --simulator
  exit
fi
unsigned=false
if [[ "${1:-}" == --unsigned ]]; then
  unsigned=true
  # This only relaxes owner preflight when Xcode also disables signing.
  # A signed release still requires the real owner's release configuration.
  export ASTRACUE_UNSIGNED_BUILD=1
else
  config="${1:-ios-release.local.json}"
  dart tool/ios_release_config.dart "$config" --configure
fi
xcode_version="$(xcodebuild -version | head -1 | awk '{print $2}' | cut -d. -f1)"
sdk_version="$(xcrun --sdk iphoneos --show-sdk-version | cut -d. -f1)"
if (( xcode_version < 26 || sdk_version < 26 )); then
  echo "App Store uploads currently require Xcode 26+ / iOS 26 SDK+." >&2
  exit 1
fi
if [[ "$unsigned" == true ]]; then
  flutter build ipa --release --no-codesign \
    --dart-define=IOS_MONETIZATION_ENABLED=false \
    --dart-define=IOS_ADS_ENABLED=false \
    --dart-define=IOS_TRACKING_ENABLED=false \
    --dart-define=FIREBASE_ANALYTICS_ENABLED=false \
    --dart-define=PLUS_DEMO_BILLING=false
else
  flutter build ipa --release --dart-define-from-file="$config"
fi
app="build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app"
if [[ ! -f "$app/Info.plist" || ! -f "$app/PrivacyInfo.xcprivacy" ]]; then
  echo "Archive is missing app metadata/privacy manifest; inspect Xcode resources." >&2
  exit 1
fi
/usr/bin/plutil -lint "$app/Info.plist" "$app/PrivacyInfo.xcprivacy"
executable="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$app/Info.plist")"
# Inspect a complete strings output (not a pipe with grep -q/SIGPIPE).
symbols="$(mktemp)"
trap 'rm -f "$symbols"' EXIT
/usr/bin/strings "$app/$executable" > "$symbols"
if /usr/bin/grep -F 'requestAlwaysAuthorization' "$symbols" >/dev/null; then
  echo "Unexpected Always Location selector in the archive. Reset SwiftPM caches and resolve with BYPASS_PERMISSION_LOCATION_ALWAYS=1." >&2
  exit 1
fi
if [[ "$unsigned" == true ]]; then
  echo "Unsigned archive built at build/ios/archive/Runner.xcarchive."
  echo "No IPA was exported. This archive cannot be installed or uploaded to App Store Connect without signing/export."
else
  echo "Archive built. Validate its privacy report and test on TestFlight before submission."
fi
