# iOS preparation verification

Date: 2026-11-12. Host: Windows. Branch: `codex/ios`, base `5b4b32e`.
Flutter used: 3.47.5, Dart 3.13.4. No native iOS build or account setup took place.

**Scope note:** The 1,693-test full-suite record below is from the initial iOS preparation, before the owner's subsequent request for the temporary free edition. Current defaults/changes are in `MONETIZATION_SWITCH.md`; follow-up free-edition verification is recorded there. Do not treat the earlier paid-flow configuration as the active iOS product.

## Commands actually run

| Check | Result / evidence |
| --- | --- |
| `flutter pub get` | Success; only `geolocator_apple` changed, 2.3.14 → 2.4.3 (direct minimum constraint for the SPM permission fix). Android geolocator remains 5.0.3. |
| `flutter gen-l10n` | Success after updating the 11 ARB files representing eight supported app languages and locale variants. |
| `flutter analyze --no-pub` | No issues; final log `build/ios-verified-analyze.log`. |
| `dart analyze lib/services/ad_service.dart` and the isolated iOS ad resolver test | No issues, **1 passed**, after making Profile use the same fail-closed ad configuration as Release. Log: `build/ios-ad-mode-check.log`. |
| `flutter test --no-pub test/ios_release_test.dart test/monetization_options_lock_test.dart --reporter expanded` | **37 passed, 0 failed**, after the final StoreKit sync guard and remaining-turns test corrections. Log: `build/ios-last-fixes-tests.log`. |
| `flutter test --no-pub test/ios_release_test.dart test/daily_energy_insight_test.dart test/home_signals_test.dart test/compass_awakening_test.dart --reporter expanded` | **80 passed, 0 failed**, after the Home prefetch/test-harness corrections; before the additional sync-timeout test. Log: `build/ios-followup-fixed-tests.log`. |
| Full Flutter suite | **1,693 passed, 0 failed**, exit 0, 10m14s. Log: `build/ios-verified-suite.log`. |
| `dart tool/ios_release_config.dart ios-release.example.json` | Expected **exit 1**; missing real Bundle ID, Team ID and published privacy/terms/support URLs rejected. No Owner.xcconfig generated. Log: `build/ios-preflight-example.log`. |
| `dart tool/export_legal_pages.dart ... --output=build/ios-legal-qa` | **27 HTML files generated** from actual localized app copy. QA-only publisher/contact used; not hosted and not release identity. |
| Git Bash `bash -n` on three iOS build scripts | Exit 0, syntax only. Mac-specific commands were not executed. |
| Plist XML parsing on Windows | Info.plist and app privacy manifest parse successfully. This is not Apple's archive validation. |
| Xcode project reference scan | All 24-character object references resolve; eight native InfoPlist.strings files exist. This is not an Xcode build/parser result. |
| SKAdNetwork list | 50 identifiers, all distinct, from the official Google iOS privacy strategies guide checked on this date. |
| App Store icon | Existing 1024px icon PNG uses RGB color type 2; no alpha channel. |
| `git diff --check` | No whitespace errors. Windows line-ending notices are not test failures; shell scripts have LF attributes. |

Logs/QA exports under `build/` are local, ignored artifacts. This document records their results for the next developer; no screenshots, customer data, receipts or signing credentials were added.

## What the new tests establish

- Dart grants through the iOS verifier only on a well-formed, matching native verdict. Foreign products/stores, bad transaction IDs, missing handlers, malformed replies and native errors cannot grant. Revocation removes cached access; unavailable verification preserves already verified access without granting a new purchase.
- Explicit restore synchronizes; startup does not. Sync is exclusive with ads, failures return checkout to idle, and timeout keeps ads guarded until the underlying native call settles. These use a **mock native channel / store**, not Apple's servers or cryptographic verification implementation.
- iOS fresh analytics is opt-in; explicit saved choices and Android's previous default survive. Release ad settings reject disabled, malformed and Google sample units.
- iOS real paywall uses the store price, hides sample discount claims, displays restore/cancellation feedback, and keeps policy/paywall text within a genuine 360×640 viewport at 1.5 text scale across eight languages with bundled fonts. Widget tests are layout measurements, not native-device visual sign-off.
- Home reuses same-day prefetch and rejects an older local day. The existing discovery animation, daily-signal refresh and onboarding transition tests pass after the helper follows the real opening ritual.
- The counter test now asserts the already approved **remaining turns** contract: `3/3 → 2/3 → 0/3`, with a separate `(+1)` earned bonus. No production quota formula was changed.

Earlier broad runs exposed the obsolete counter expectation and onboarding prefetch/helper failures; they were corrected. An interim run overlapped the final timeout-guard edit; its failing guard test passed in a fresh process, followed by the clean full-suite run recorded above. Use that completed record rather than the interim logs.

The final small ad-mode adjustment makes Profile follow Release's fail-closed configuration (`!kDebugMode`); Debug behavior is unchanged. The ad resolver test explicitly covers both mode branches. Native Profile execution remains part of Mac QA, not a claim established by the Windows suite.

Debug.xcconfig explicitly sets the Swift `DEBUG` compilation condition so local Xcode StoreKit transactions can be tested in Debug; Release/Profile do not inherit that setting. This native build setting was inspected on Windows, not compiled by Xcode here.

## Not verified here

- Swift/Xcode compilation, SwiftPM resolution on macOS, code signing, provisioning, archive export or App Store upload.
- Native `RunnerTests` (bundle privacy/defaults and eight purpose-string localizations). Written, **not executed**.
- Actual StoreKit 2 verification, Apple sandbox/TestFlight purchase/restore, Ask to Buy, refund/revocation, reinstall and cross-device restoration.
- Native UMP/ATT forms/callback/lifecycle ordering, ad fill, paid events, real SDK consent collection, denied tracking after Settings changes and native share-popover appearance.
- Actual signed-archive Privacy Report, SDK privacy signatures, required-reason aggregation, Always Location selector check and App Store Connect validation. The build script includes archive checks for execution on Mac.
- Live ownership/configuration of Bundle ID, team, product, AdMob IDs, Firebase project or publicly hosted policy/support pages. No owner identities/accounts/URLs were invented.
- iPhone/iPad screenshots and human visual QA, age/content rating, App Privacy answers, export compliance, first-IAP submission and App Review acceptance.

The engine/formula directories, model contracts and Android native files have no changes from this task. Existing unrelated edits to `CLAUDE.md`, release/audit/marketing documents, store artwork and `review/` screenshots were preserved.

See `IOS_RELEASE.md` for the owner/Mac handoff and official sources. iOS readiness is conditional on the outstanding native checks and real account configuration.
