# AstraCue iOS release handoff

Branch: `codex/ios`, based on `origin/main` at `5b4b32e`. Prepared 2026-11-12.

**Current owner-approved build: free iOS edition.** Ads and VIP are temporarily disabled by default with `IOS_MONETIZATION_ENABLED=false`; Android is unchanged. Decisions, categories, valid periods and guidance are unmetered, without fake Plus activation or rewarded grants. See `MONETIZATION_SWITCH.md`. The billing/ads implementations below are retained for a later explicit re-enable, not active purchase offers in this build.

This is release preparation, **not an uploaded or approved iOS release**. Swift compilation, signing, StoreKit, UMP/ATT and device lifecycle behavior still need a Mac and real device verification. No Apple/AdMob/Firebase account or credential was fabricated or registered.

## Implemented

- iOS signing/build settings; iOS 15 minimum, iPhone + iPad retained. An opaque 1024px RGB App Store icon already exists.
- Native StoreKit 2 verification: `Transaction.latest(for:)`, Apple's `.verified` result, matching product/transaction, non-consumable type and revocation. No decode-only receipt check or hardcoded grant. Release rejects Xcode-local transactions on iOS 16+; sandbox remains allowed for TestFlight.
- Explicit Restore calls `AppStore.sync()` before querying ownership; startup queries remain silent. Existing completion/recovery/persistence, quota and rewards continue through the shared controller.
- Real iOS purchases use the store's formatted price without the unsupported reference price/discount. Demo preview and Android presentation retain existing behavior. Localized pending/cancel/error/restore feedback; pending checkout can be closed.
- Privacy/Terms pages and links from Responsible Use and the iOS paywall, in eight languages. Hosted links use native Safari. Visiting a policy does not record agreement or bypass the scroll-to-agree gate.
- Fresh iOS analytics defaults off; the native Boolean `FIREBASE_ANALYTICS_COLLECTION_ENABLED` is false before Dart runs. Saved choices are respected; IDFV collection/default ad personalization signals are disabled, and runtime analytics consent denies ad storage/user data/personalization.
- Separate iOS ad units and enablement. Release/Profile never fall back to Google samples; profile ad testing requires the same owner settings as release. UMP precedes SDK startup; optional ATT runs within the exclusive consent phase before ads. Declining does not block use. Without authorization, ad requests are non-personalized; publisher first-party ID is disabled.
- App privacy manifest, eight localized native purpose strings and the official Google/buyer SKAdNetwork list. Normal readings use device timezone without GPS. No background location capability.
- `geolocator_apple` minimum 2.4.3: SPM now honors `BYPASS_PERMISSION_LOCATION_ALWAYS=1`, unlike the previously installed 2.3.14. Build script exports the flag; Android's package remains unchanged.
- iPad share-popover anchor. Release preflight, optional genuine Firebase configuration copy, and native bundle/localization smoke tests.
- Onboarding's preloaded daily brief is now reused by Home on the same local day instead of calculated twice; a midnight rollover invalidates it. The test helper follows the opening screen's real tap-to-skip action before checking Home's one-shot animation. Presentation and calculation formulas are unchanged.

The Android Block Store backup channel still has no iOS implementation; its existing missing-plugin fallback preserves local state. No reinstall-resistant limits or cross-device profile/history sync are promised. Restore recovers Plus, not local history. Formulas, categories, saved result contracts and quotas have not been redesigned.

## Owner settings

Copy `ios-release.example.json` to **`ios-release.local.json`** inside `mobile_app`:

| Setting | Required value |
| --- | --- |
| `IOS_BUNDLE_ID` | Explicit Bundle ID registered to your Apple team and App Store Connect app |
| `IOS_DEVELOPMENT_TEAM` | 10-character Apple Team ID |
| `IOS_MONETIZATION_ENABLED` | Keep `false` for the current free iOS edition |
| `IOS_PLUS_PRODUCT_ID` | Optional/empty while disabled; registered **non-consumable** only when monetization is re-enabled |
| `PRIVACY_POLICY_URL`, `TERMS_OF_USE_URL`, `SUPPORT_URL` | Published HTTPS pages, including real publisher/contact details |
| `IOS_ADS_ENABLED` | Enable only after real iOS AdMob configuration is ready |
| `ADMOB_IOS_APP_ID` | Your iOS App ID (`~` separator) |
| `ADMOB_IOS_*_UNIT_ID` | Your banner/interstitial/rewarded units (`/` separator) |
| `IOS_TRACKING_ENABLED` | Enable only when cross-app tracking is intended and declared correctly |
| `FIREBASE_ANALYTICS_ENABLED` | Optional; requires genuine matching iOS `GoogleService-Info.plist` |
| `PLUS_DEMO_BILLING` | Always `false` for App Store/TestFlight |

The JSON and generated `ios/Flutter/Owner.xcconfig` are ignored. They contain public settings, **not** signing certificates, passwords, private keys or Apple API keys. Do not put secrets in Dart defines; they are extractable. Structural validation cannot prove account ownership, live product availability or reachable/legal web pages.

For a later paid edition, the agreed USD base price is **$4.99 one time**. Set price and regions in App Store Connect; Apple supplies localized currency strings. Paid-app agreements, tax/banking and IAP setup are only needed when re-enabling purchases. The first IAP may need submission with that app update. Android's real verifier remains unconfigured; this branch retains the iOS verifier for later use.

For Firebase, register this Bundle ID in the correct project and place its file at `ios/Runner/GoogleService-Info.plist`. The release build checks its Bundle ID. Leave the flag false until ready; no fake configuration is generated.

## Publish policy/support pages

Export the same localized text used in-app into 27 static HTML pages:

```sh
dart tool/export_legal_pages.dart --publisher="YOUR REAL LEGAL NAME" --email=YOUR_REAL_SUPPORT_EMAIL --output=build/legal
```

Replace both placeholders with actual details. Review against your actual data processing and legal obligations, then host over HTTPS. Defaults: `privacy.html`, `terms.html`, `support.html`; eight localized alternatives are included. Support includes the real contact email. No publishing occurs in the script. Configure these URLs in the release JSON and App Store Connect; review/re-export if processing changes.

## Cloud compilation without an Apple account

The `iOS unsigned build` GitHub Actions workflow runs on the standard `macos-26`
runner for pushes affecting the app on `codex/ios`. It installs Flutter 3.47.5
(Dart 3.13.4), resolves the committed dependencies and compiles a release archive.
It does **not** run Flutter analysis, automated tests or device tests. Ads, VIP,
ATT and Firebase analytics remain disabled for this iOS build.

Download `AstraCue-iOS-UNSIGNED-<run number>` from the successful workflow run's
Artifacts section within one day. It contains the `.xcarchive.zip`, build
information and a checksum. The archive preserves bundle permissions/symlinks.
This is **not** a signed IPA: it cannot be directly installed on iPhone, used for
TestFlight or uploaded to App Store Connect. Do not rename it to `.ipa`.

The same compile-only command on a Mac is:

```sh
cd mobile_app
export BYPASS_PERMISSION_LOCATION_ALWAYS=1
flutter pub get --enforce-lockfile
bash tool/build_ios.sh --unsigned
```

Unsigned compilation explicitly opts out of owner preflight only when Xcode's
`CODE_SIGNING_ALLOWED` is also `NO`. Normal signed builds keep the Team ID,
published legal/support URLs and production configuration checks. When Apple
setup is ready, build/export again with the real release JSON below.

Standard hosted runners for a public repository have no compute charge. Artifact
storage has separate limits; this workflow retains its output for one day and
does not configure billing, caches, Apple accounts or store upload. See
https://docs.github.com/en/billing/concepts/product-billing/github-actions.

## Build and sign for distribution on macOS

Need Apple Developer Program membership, signing access, Xcode 26+ / iOS 26 SDK+, and Flutter with **Dart 3.13.4+ within 3.x**, matching `pubspec.yaml`. An older stable Flutter may not meet this constraint. Accept Xcode agreements, install iOS simulators/platform support, sign in under Xcode Settings > Accounts and run `flutter doctor -v`. Deployment remains iOS 15.

```sh
cd mobile_app
flutter pub get
flutter gen-l10n
flutter analyze
flutter test

# Account-free simulator demonstration of the current free edition.
bash tool/build_ios.sh --demo

# Validate settings, generate native xcconfig, sign and archive.
bash tool/build_ios.sh ios-release.local.json
```

The release command passes the **same** JSON to Dart and native settings, exports the foreground-only location flag, and checks Xcode/SDK versions. For Xcode GUI builds, launch Xcode from a shell exporting `BYPASS_PERMISSION_LOCATION_ALWAYS=1` before SwiftPM resolves packages. If already resolved without it, reset/re-resolve package caches with the variable set; inspect the compiler define in the build log. Do not add Always Location permission as a workaround.

After building, the script checks the packaged plists and rejects an unexpected `requestAlwaysAuthorization` selector in the app binary. This catches a stale SwiftPM permission build; it is not a complete privacy report or native UI test.

Open `ios/Runner.xcworkspace` after configuration and confirm Runner team, Bundle ID and automatic signing. No Push Notifications, background location or online account sign-in capability is needed by the current features. Preflight intentionally rejects blank owner settings; do not bypass it to ship preview IDs/pricing.

Successful `flutter build ipa` creates an archive under `build/ios/archive/` and an IPA under `build/ios/ipa/` after signing/export. Validate/distribute through Xcode Organizer or supported Apple upload tooling. Increment the build number on later uploads. Team-specific certificate/provisioning setup cannot be completed on Windows.

Run native `RunnerTests` in Xcode on iPhone and iPad simulators; these check packaged privacy defaults/purpose localizations. They have **not run on Windows**. Widget tests targeting iOS do not compile Swift or exercise native stores/ads.

## Required native QA and submission

1. Fresh install/relaunch in all eight languages; small/notched iPhone, iPad, portrait/landscape and large text. Check profile/date/AM-PM birth time, cooldowns, policies and scroll-to-agree. Opening policies/Back must never grant agreement.
2. Current free build: verify no VIP/upsell/quota/reward UI, banners, automatic interstitials, purchase/restore/consent/ATT prompts or blocked readings, including installs with old exhausted/locked records. Data must survive unchanged. StoreKit local configuration and sandbox/TestFlight payment scenarios become required when re-enabling monetization: buy, cancel, pending, restore/reinstall/second device, process death, duplicates and refund/revocation. Restore must never refill quota.
3. With the current flag off, UMP/ATT and ad startup remain dormant. On a later ad-enabled build, test UMP required/not-required/failure/recovery, ATT allow/deny/restricted/Settings changes and exclusive fullscreen flows. Refusal must not block the app. NPA does **not** mean no SDK data collection.
4. Real ad preload/failure/backoff, dismiss-without-reward vs earned, external links, rotation and resume. Preserve current rules: first daily reading protected, no Home-return interstitial, 30s interstitial gap, no post-result interstitial for a rewarded reading, History subject to policy. No new rewarded gap or daily interstitial cap. Plus removes automatic ads; optional rewarded follows current product rules.
5. Local-midnight reset, cooldown recovery, immutable history, iPad sharing, timezone/DST and network-guard recovery. The engine is local, but the approved app-level network guard requires connectivity; do not advertise the full app as offline-capable.
6. Inspect the signed archive's **Privacy Report**, SDK manifests/signatures and required-reason APIs. App manifest covers the app's processing, not every SDK. Combine with actual Firebase/AdMob behavior when answering App Privacy; do not claim “Data Not Collected” while those SDKs process data. Refresh SKAdNetwork IDs if partners change.
7. Create the App Store Connect app, choose countries/content rating and supply accurate App Privacy, privacy/support URLs, Apple-device screenshots, export-compliance answers and reviewer notes. Current submission is free, without ads or IAP; describe the actual free features and optional usage analytics. Do not submit a Plus product or claim paid benefits for this build. Encryption answers depend on the binary; no blanket exemption was injected. No login is needed. IAP setup/reviewer instructions apply only on re-enable.
8. Describe results as symbolic reflection/entertainment, not medical/financial advice, scientific predictions or real success probabilities. **Guideline 4.3(b)** treats fortune-telling as saturated and requires meaningful differentiation/improvement. Explain the real decision workflows/personalization; a build or disclaimer cannot guarantee approval.

See `IOS_VERIFICATION.md` for commands actually run. Real accounts, hosted URLs, signing, native compilation/device QA and submission remain owner-dependent.

Official references checked 2026-11-12:

- https://docs.flutter.dev/deployment/ios
- https://developer.apple.com/news/upcoming-requirements/
- https://developer.apple.com/app-store/review/guidelines/
- https://developer.apple.com/documentation/storekit/transaction/latest(for:)
- https://developer.apple.com/documentation/storekit/appstore/sync()
- https://developers.google.com/admob/ios/privacy/strategies
- https://firebase.google.com/docs/analytics/ios/configure-data-collection
- https://github.com/Baseflow/flutter-geolocator/blob/main/geolocator/README.md
