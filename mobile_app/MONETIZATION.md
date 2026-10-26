# Reading quota implementation

Updated 2026-10-26. Quota rules are unchanged. Ad lifecycle implementation and
remaining production prerequisites are documented in `ADS_LIFECYCLE.md`.

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
selection-option gates, reward CTA/grants and actual free/bonus
credit use. See `TRACKING.md`. Option unlocks remain separate from bonus
credits. The 2026-10-26 SDK flow uses `grant_source=sdk` and adds separate ad
lifecycle events. Tracking acceptance/withdrawal and the optional no-op sink
still apply; test ads are not evidence of commercial revenue.

Regression coverage is in `test/reading_quota_controller_test.dart`, `test/monetization_completion_test.dart` and `test/monetization_ritual_ui_test.dart`.

These cover the fourth-use refusal, local-day accounting, the three-hour boundary, 00:00 reset, restart and legacy state, concurrent commits, untouched bonus cooldown, failure and retry, non-billable states, direct-entry and preview bypasses, and leaving an unfinished attempt.

## Ads lifecycle (2026-10-26)

- First daily successful reading and its immediate History flow: no interstitial.
- Later successful **free** readings: an interstitial candidate before Result.
- A reading consuming bonus credit: no post-analysis interstitial.
- History row tap: a candidate unless within the first reading's protected flow.
- No automatic fullscreen ads on Home, app resume, or a timer. No queued/delayed catch-up.
- A shared 30-second minimum gap from interstitial dismissal, persistent across
  restart/midnight. No separate reward gap and no daily interstitial cap.
- Missing/unavailable ad: continue immediately; a ready native fullscreen ad:
  wait for its actual dismissal/failure, never an eight-second fake dismissal.
- Reward grants only after `onUserEarnedReward`, with deduplication. Reading
  credit persists immediately; dismissing an unearned ad grants nothing.
- Preload/retry/expiry/UMP details and verification: `ADS_LIFECYCLE.md`.

## Still outside this change

Only test AdMob IDs are configured. UMP is wired, but requires real account
message configuration and device QA. Home/Reveal banner SDK wiring is now
implemented using ordinary anchored-adaptive Google test units; the old fake
advertiser/CTA has been removed. Refresh is owned by SDK/AdMob, not an app
timer. Banner placement, privacy/lifecycle and production ID configuration are
documented in `ADS_LIFECYCLE.md`. Server-side entitlement is not implemented.

This is local device enforcement, not tamper-proof server entitlement. Do not claim protection against manually changing the device clock, clearing app data or multiple app installations.

