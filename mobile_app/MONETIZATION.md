# Reading quota implementation

Updated 2026-10-09. This note describes app-owned entitlement logic, not live ad serving.

## Confirmed rules

- Up to three successful free readings per device-local calendar day, shared by all modes and categories.
- A successful free reading starts a three-hour cooldown at completion, capped at the next local midnight.
- At exactly local 00:00, both the used-free count and the free cooldown reset. The first free reading of the new day is immediately available.
- Bonus credits survive midnight. Using a bonus does not increment free usage or move the free cooldown. The existing bonus-first priority is unchanged.
- `ready` and `balanced` responses with a usable percentage split consume one entitlement. Exceptions, malformed splits, `insufficient_data`, `period_elapsed` and leaving an unfinished analysis do not.
- Retries spend nothing until they successfully complete. A Loading instance commits at most once.

## Enforcement and persistence

- Ritual verifies real entitlement before beginning. Its category badge and long press no longer switch demo lock states.
- Loading also checks entitlement before calculating, so direct entry cannot bypass the gate.
- The quota controller rechecks availability at successful commit. Mutations are serialized, preventing concurrent taps or callbacks from exceeding the quota.
- The calculation snapshot retains the original UTC Reveal instant. Quota accounting instead receives the device-local completion time; these clocks must not be confused.
- Persistent counters, local day, last free completion and bonus balance are committed together in `reading_quota_state_v1`. Memory is updated only after the write succeeds. Existing four-key records remain readable and migrate on their next mutation.
- No engine formulas, mode/category coefficients or saved result snapshots were changed.

## Verification

The 2026-10-09 instrumentation extension records locked reading actions,
selection-option gates, prototype reward CTA/grants and actual free/bonus
credit use. See `TRACKING.md`. It does not change any entitlement or UX rule,
does not treat option unlocks as bonus credits, and does not count real ads or
revenue. Tracking acceptance/withdrawal and the optional no-op sink still apply.

Regression coverage is in `test/reading_quota_controller_test.dart`, `test/monetization_completion_test.dart` and `test/monetization_ritual_ui_test.dart`.

These cover the fourth-use refusal, local-day accounting, the three-hour boundary, 00:00 reset, restart and legacy state, concurrent commits, untouched bonus cooldown, failure and retry, non-billable states, direct-entry and preview bypasses, and leaving an unfinished attempt.

## Interstitial Ad Implementation (2026-10-15)

- **Scenario**:
  - **1st reading of the day**: 100% clean experience, no interstitial ad shown.
  - **2nd reading of the day onwards**: Interstitial ad triggers immediately after analysis loading finishes. The aperture transition and navigation to the Result page only happen after the ad is dismissed (or if ad loading fails / times out after 8s safety window).
- **AdMob IDs & Real ID Replacement**:
  - Currently configured with Google's official Test AdMob Unit IDs (safe for testing without getting banned).
  - Android Manifest: `ca-app-pub-3940256099942544~3347511713` (Test App ID in `AndroidManifest.xml`).
  - iOS Info.plist: `ca-app-pub-3940256099942544~1458002511` (Test App ID in `Info.plist`).
  - Ad Unit ID: Configured in `lib/services/ad_service.dart` via `AdConstants`.
  - When ready with real AdMob account:
    1. Update App ID in `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist`.
    2. Set `realAndroidInterstitialUnitId` and `realIosInterstitialUnitId` in `lib/services/ad_service.dart`.
- **Fail-safe Design**:
  - Preloads in background at app start and on loading page initialization.
  - An 8-second safety timeout ensures the user is never stuck if the ad fails to show or hangs.
  - In airplane mode or if AdMob fails to fill, it immediately bypasses and reveals the result.

## Still outside this change

Rewarded ads remain a prototype: the current button directly calls `earnBonusReading`. In a live ad integration this must only follow the SDK reward callback. Banner SDK integration, ad consent, and server-side entitlement are not implemented.

This is local device enforcement, not tamper-proof server entitlement. Do not claim protection against manually changing the device clock, clearing app data or multiple app installations.

