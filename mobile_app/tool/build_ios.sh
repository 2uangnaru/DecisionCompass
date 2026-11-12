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
config="${1:-ios-release.local.json}"
dart tool/ios_release_config.dart "$config" --configure
xcode_version="$(xcodebuild -version | head -1 | awk '{print $2}' | cut -d. -f1)"
sdk_version="$(xcrun --sdk iphoneos --show-sdk-version | cut -d. -f1)"
if (( xcode_version < 26 || sdk_version < 26 )); then
  echo "App Store uploads currently require Xcode 26+ / iOS 26 SDK+." >&2
  exit 1
fi
flutter build ipa --release --dart-define-from-file="$config"
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
echo "Archive built. Validate its privacy report and test on TestFlight before submission."
