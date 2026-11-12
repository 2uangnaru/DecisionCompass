#!/bin/sh
set -eu
[ "${CONFIGURATION:-}" = Release ] || exit 0
[ "${PLATFORM_NAME:-}" = iphoneos ] || exit 0
fail() { echo "error: AstraCue iOS release: $1" >&2; exit 1; }
[ -n "${DEVELOPMENT_TEAM:-}" ] || fail 'Set your Apple Team ID through ios-release.local.json.'
for setting in ASTRACUE_PRIVACY_POLICY_URL ASTRACUE_TERMS_URL ASTRACUE_SUPPORT_URL; do
  case "$setting" in
    ASTRACUE_PRIVACY_POLICY_URL) value="${ASTRACUE_PRIVACY_POLICY_URL:-}" ;;
    ASTRACUE_TERMS_URL) value="${ASTRACUE_TERMS_URL:-}" ;;
    ASTRACUE_SUPPORT_URL) value="${ASTRACUE_SUPPORT_URL:-}" ;;
  esac
  case "$value" in https://?*) ;; *) fail 'Configure published HTTPS privacy, terms and support pages.' ;; esac
done
product=''
monetization=false
ads=false
tracking=false
firebase=false
old_ifs="$IFS"
IFS=,
for encoded in ${DART_DEFINES:-}; do
  decoded="$(printf '%s' "$encoded" | /usr/bin/base64 -D 2>/dev/null || true)"
  case "$decoded" in
    IOS_PLUS_PRODUCT_ID=*) product="${decoded#*=}" ;;
    IOS_MONETIZATION_ENABLED=true) monetization=true ;;
    PLUS_DEMO_BILLING=true) fail 'Demo billing cannot be used in an App Store build.' ;;
    IOS_ADS_ENABLED=true) ads=true ;;
    IOS_TRACKING_ENABLED=true) tracking=true ;;
    FIREBASE_ANALYTICS_ENABLED=true) firebase=true ;;
  esac
done
IFS="$old_ifs"
if [ "$monetization" = true ]; then
  [ -n "$product" ] && [ "$product" = "${ASTRACUE_PLUS_PRODUCT_ID:-}" ] ||
    fail 'Run tool/build_ios.sh with the release JSON so native and Dart product IDs match.'
elif [ "$ads" = true ] || [ "$tracking" = true ]; then
  fail 'Ads/tracking must be disabled while iOS monetization is off.'
fi
if [ "$ads" = true ]; then
  case "${ASTRACUE_ADMOB_APP_ID:-}" in
    ca-app-pub-3940256099942544*|'') fail 'Configure your genuine iOS AdMob App ID.' ;;
  esac
fi
if [ "$firebase" = true ]; then
  [ -f "${PROJECT_DIR}/Runner/GoogleService-Info.plist" ] || fail 'Firebase is enabled without its genuine iOS configuration.'
  firebase_bundle="$(/usr/libexec/PlistBuddy -c 'Print :BUNDLE_ID' "${PROJECT_DIR}/Runner/GoogleService-Info.plist" 2>/dev/null || true)"
  [ "$firebase_bundle" = "${PRODUCT_BUNDLE_IDENTIFIER:-}" ] || fail 'Firebase Bundle ID must match the signed iOS app.'
fi
