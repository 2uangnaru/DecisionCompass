# Ads lifecycle: agreed rules and implementation

Updated 2026-10-26. Android-first. No scoring, quota, saved-reading schema,
branding assets or production ad configuration changes.

## Product rules

| Candidate action | Interstitial behavior |
| --- | --- |
| First successful new reading of local day | Never |
| History reached from that first reading | Never, including its snapshot screens |
| Later new reading using a free credit | Consider after usable analysis, before Result |
| New reading using bonus/reward credit | Never after analysis |
| Tap saved result in History before any new reading has been viewed today | Never (daily eligibility not yet earned) |
| Tap saved result in History after today's first viewed reading, outside its protected flow | Consider before that exact snapshot |
| Home/back/resume, idle timer, load completion | Never |

Both candidates use one **30-second gap from the previous interstitial's
native dismissal**, persisted in `ad_policy_v1` with the viewed local day.
There is **no daily interstitial cap and no separate rewarded gap**. For
example, rewarded can be followed immediately by an eligible History
interstitial if the prior INTERSTITIAL gap is satisfied. It still cannot
overlap another fullscreen ad. Failure to show does not start a dismissal gap.

The first-daily marker records a billable Result's first rendered frame, not
merely quota consumption. The first result propagates a protected-flow flag
through its own History/snapshot branch until the reader leaves that flow.
History replay does not calculate, consume quota, resave or change a snapshot.
Existing installs with no ad-policy record conservatively stay ad-free until
they view a new successful result. Midnight resets first-day eligibility but
does NOT erase the last interstitial dismissal. Clock rollback blocks a gap
until the timestamp catches up; this is not server-backed tamper protection.

## Architecture

- `lib/services/ad_policy.dart`: serialized persistent day/gap state. Broken
  storage disables automatic interstitials; reads/writes have a three-second
  deadline. An in-memory dismissal still takes effect when disk fails.
- `lib/services/ad_runtime.dart`: injected SDK-free coordinator. One ready ad
  per format; both share one fullscreen lock. Candidate calls skip immediately
  when uninitialized, consent-blocked, backgrounded, busy, or not ready.
- `lib/services/ad_service.dart`: Google Mobile Ads/UMP adapter, Google test
  interstitial/rewarded/banner units by default. No raw SDK error strings are logged.
- `LoadingPage`: only later **free** usable completions request interstitials.
- `HistoryPage`: one in-flight row action for the whole page; checks route and
  mounted state before/after the ad. Ten rapid taps do not queue ten opens.
- `ResultPage`: rendered billable results mark daily eligibility. History
  snapshots never do. No interstitial was added to a Home-return action.

## Preload, retry and lifecycle

- Initialize only after content is mounted. UMP updates consent info each
  launch, loads/shows any required consent form, and gates SDK initialization
  and ad requests on `canRequestAds`. The sequencing lives in
  `ManagedAdService`; `GoogleAdsBackend` only exposes the UMP/SDK calls.
- Steps that show no UI (consent-info update, `canRequestAds`, privacy
  requirement, SDK start) are bounded at 15 seconds. After an update error
  or timeout the SDK's own `canRequestAds()` is asked, so consent kept from
  an earlier session still serves ads; no app-side consent flag exists.
- A consent or privacy form is never timed out. A timeout is not evidence a
  native form closed, so the shared fullscreen guard is held until UMP's
  dismissal callback arrives: no ad, second form or privacy-options call can
  start over it, and a late dismissal resumes normally.
- Recovery: a retryable failure (update error/timeout, failed consent/privacy
  form, unknown permission, SDK start failure) is tried again on a later
  foreground resume, at most once a minute, one attempt at a time. Only a
  successfully completed collection with SDK permission still unavailable
  suppresses another automatic collection for that session. Resume never
  displays an ad.
- P2 follow-up: form methods return `ConsentFormOutcome.completed/failed`.
  The Google adapter now preserves callback `FormError` instead of treating
  every resolved form future as a completed choice. Both initial consent and
  privacy-options failure can recover; `canRequestAds()` remains authoritative.
  A privacy-options attempt also starts the existing one-minute retry spacing.
- **Residual limitation:** if UMP never delivers the form-dismissal callback,
  ads and privacy options stay disabled until the next cold start. That is
  deliberate: no API reports that the form is gone, and inventing a
  dismissal could put an ad over a visible consent form.
- Required UMP privacy choices are available in Responsible Use (all eight
  app languages). Opening choices invalidates caches/in-flight loads before
  rechecking permission. Analytics consent is separate and unchanged.
- Keep at most one ready interstitial and one ready rewarded. Duplicate
  loading/valid-cache calls do nothing. Consumed ads are removed before show.
- Load timeout: **15 seconds**. It is not an ad-duration timer.
- Retry: **2, 4, 8, 16, 32, 64, 64... seconds**; success resets attempts.
  Background cancels scheduled retries/refreshes, resume checks/preloads only.
- App-owned cache lifetime: **50 minutes**. Expired or clock-invalid cache is
  disposed/refreshed, never shown. No copy of Titan's level-based gating.
- Generation checks discard late load successes and ignore stale failures;
  they cannot replace a newer cached ad or display on a later screen.
- Duplicate load callbacks are recognised by the NATIVE ad
  (`FullscreenAd.identity`), not the wrapper: the Google adapter builds a
  fresh wrapper per callback, so wrapper identity alone would dispose an ad
  that is cached or on screen. A genuinely different stale ad is disposed.
- Native dismissal/failure releases the shared fullscreen lock, disposes the
  consumed ad, preloads the next, and resolves the continuation exactly once.
  There is NO show-duration watchdog: navigation cannot run under a still-open
  native ad merely because eight seconds elapsed.

## Rewards

All four existing reward placements (reading, mode, category, period) now use
the SDK earned callback rather than the CTA itself. One callback receipt per
show; duplicates and callbacks after terminal dismissal/failure are ignored.
Google AdMob earned callbacks arrive before dismissal; a mediation adapter
with different ordering must be re-audited before adoption.

For reading credit, `earnBonusReading` starts immediately on earned callback,
even if the originating widget was disposed, and is awaited before reward
success is returned. Closing without earning does not grant. No retries of
reward writes or ad shows are invented.

A save failure after an earned callback returns `AdOutcome.rewardSaveFailed`,
distinct from a voluntary close (`dismissed`). No `reward_granted` is sent;
the still-mounted page shows the localized `adRewardNotSaved` notice (eight
languages and the three alias files). Raw storage/SDK errors are not shown,
logged or tracked.
Option unlocks retain their existing screen-lifetime behavior and are NOT
bonus credits. Since 2026-10-28 a locked mode, category or period plays its
rewarded ad straight from the tap (the AD badge is the disclosure); the old
confirmation sheet was removed, so `reward_cta_tapped` fires on that tap. The existing option gates/free quota/cooldown are unchanged.

If an ad is unavailable/fails, show a localized short notice; never fabricate
a successful view or bonus. NoOp grants nothing. Tests/previews needing a
reward must explicitly inject `TestRewardAdService` from the test harness.

## Plus ad-free (2026-10-29)

`AdService.setAdFree(true)` follows the verified Plus entitlement: cached
ads are disposed, in-flight loads are discarded by generation, no request
is made, every fullscreen candidate skips with reason `ad_free`, and banner
slots lose permission (their AdWidget is removed). Revocation preloads as a
free user would; nothing is shown on resume. Store checkout claims the shared
fullscreen guard (`claimFullscreen`), so no ad or UMP form can overlap it;
pending, update, failure or app resume releases it. Plus also bypasses the
mode/category/period and Action Guidance rewarded gates. See
`PLUS_BILLING.md`.

## Action Guidance lock (2026-10-28)

The first **three** new usable readings on a device show Action Guidance
(Should / Avoid). Every later new reading, free or bonus, renders the card
with its tags readable and the text blurred behind the shared
`WatchAdButton` (the Ritual pill, now in `celestial_ui.dart`). The rewarded
ad uses placement `guidance` / `RewardPlacement.guidance`; only the SDK
earned callback plus a successful save opens it, permanently for that
`readingKey` (History reopens it open). It grants NO reading credit, and the
Ritual reward opens no guidance: the button is shared, the handlers are not.
The automatic after-analysis interstitial is unchanged, so a locked reading
can be followed by a voluntary rewarded ad (owner decision).

- `lib/data/guidance_lock_store.dart`: count plus open/locked key lists in
  SharedPreferences. Only readings admitted past the allowance can be locked,
  so pre-existing History stays readable; existing installs start at zero.
  A repeat of an open key spends nothing. Storage failure shows guidance.
- The count is mirrored to **Google Block Store** (`astracue/block_store`
  channel in `MainActivity`, `play-services-auth-blockstore:16.4.0`,
  `setShouldBackupToCloud(true)`); the larger of the two counts wins. Google
  documents it surviving uninstall/reinstall only with Backup on. Whether
  Android "Clear data" erases it is undocumented and NOT device-verified.
  It is not tamper-proof; no server exists.
- Tests: `test/guidance_lock_test.dart`.

## Banner (2026-10-26)

The `Astra Store` house-ad mock has been removed. Only Home and Reveal have
ordinary **standard anchored-adaptive** AdMob banners, not collapsible overlays.
Loading, Result, History, Profile, onboarding and Responsible Use have no slot;
a modal sheet hides the underlying banner. First-daily protection is for
interstitials only: banner eligibility does not depend on reading quota.

- `banner_ad.dart` defines a separate injectable SDK boundary; banner is NOT
  added to fullscreen `AdFormat` or its two preload caches.
- `banner_ad_controller.dart` owns one native handle per mounted slot. Home
  can retain its own hidden banner while Reveal owns another. Popping back
  reuses Home's handle. No native ad is mounted in two AdWidgets.
- `ad_banner_slot.dart` uses `ModalRoute.isCurrentOf` (including sheets), actual
  available width and shared permission/foreground/fullscreen state. Hidden
  slots REMOVE AdWidget, rather than making a mounted ad transparent. Native
  disposal waits until the next frame, after AdWidget is removed.
- UMP permission AND successful SDK startup gate initial requests. Privacy
  collection/withdrawal invalidates visible and hidden banners. Native banner
  click overlays hold the shared fullscreen guard until their closed callback,
  even if their route disappears; no fabricated dismissal timer.
- Initial sizing/load deadline is 15 seconds, with one 2/4/8/16/32/64-second
  backoff chain. No retries while off-route, backgrounded or fullscreen-busy.
  Sizing finishing after a slot is hidden cannot start a new native load.
  Stale callbacks cannot resurrect old banners.
- After initial success, SDK/AdMob owns refresh and refresh-error recovery.
  There is **no app refresh timer**, reload on build, or retry loop alongside
  a loaded SDK banner. Set **Google-optimized automatic refresh in AdMob**
  when creating the real banner unit; this console setting cannot be set by
  app code and has NOT been configured in this checkout.
- Width changes recreate the correctly sized banner. Exact SDK height is
  reserved before creative display, plus 8dp separation above. The initial
  50dp reservation can adjust once when SDK sizing resolves or width changes,
  not when the creative loads/refreshes. On no-fill a small blank reservation
  remains to avoid shifting controls; no fake advertisement or blocking UI.
  Existing scaffold SafeArea keeps it above system navigation. NoOp has no slot.
- Plugin 9.1 deprecates standard sizing in favour of **large** anchored (up to
  150dp). A documented line-local suppression retains the agreed compact
  standard format (up to 90dp), rather than silently expanding the UI.
  Revisit this API when upgrading the SDK.

### Production configuration (owner supplies later)

`AdConstants` in `ad_service.dart` contains Google's default adaptive **test**
units. An Android production banner unit can be supplied at build time:

```powershell
flutter build apk --release --dart-define=ADMOB_ANDROID_BANNER_UNIT_ID=YOUR_REAL_BANNER_UNIT_ID
```

An empty define uses Google's test unit. `ADMOB_IOS_BANNER_UNIT_ID` is also
available, but iOS behavior is not device-verified. The Android manifest still
has a sample AdMob **App ID** (not an ad unit ID); replace it with the owner's
App ID and configure UMP messages before production. Interstitial/rewarded IDs
are unchanged and still test units. Supplying a banner unit alone is NOT
production sign-off: account setup, native QA and store/privacy checks remain.

## Analytics

The existing thirteen product events remain. Reward CTA/grant events from the
SDK path use `grant_source=sdk`; prototype remains a valid historical/test
source. Eleven additional closed-vocabulary lifecycle events:

`ad_request`, `ad_loaded`, `ad_load_failed`, `ad_skipped`, `ad_show_requested`,
`ad_show_failed`, `app_ad_impression`, `ad_clicked`, `ad_paid`,
`ad_dismissed`, `ad_reward_save_failed`.

The impression event is `app_ad_impression`, not `ad_impression`: that name
belongs to Firebase (collected by the Google Mobile Ads SDK once AdMob is
linked, and listed as reserved in some Firebase references). Logging it from
the app would double-count or be dropped. The SDK's own events are not
renamed, suppressed or duplicated. See
https://firebase.google.com/docs/analytics/measure-ad-revenue.

Only format, placement, fixed skip/failure reason and SDK paid value/currency/
precision are allowed. `value_micros` is SDK micro-units, **not dollars**.
Only impression callback counts impressions; a show request is not revenue.
Malformed currency/precision/value is omitted. No IDs, birth details,
coordinates, reading keys, raw error text or diagnostics are collected.
Analytics withdrawal/no-op behavior stays as before. Test ad events do not
demonstrate commercial earnings. Firebase delivery remains unverified.

## Verification and review entry points

- `test/ad_runtime_test.dart`: controller, policy, persistence, retry/cache,
  consent gating, late callbacks, fullscreen/gap/no-cap and reward receipt tests.
- `test/interstitial_ad_flow_test.dart`: actual Loading/Result/History wiring,
  free versus bonus, protected first flow, immutable replay and rapid taps.
- `test/rewarded_ad_flow_test.dart`: Ritual SDK-callback-to-persistent-credit
  wiring, unearned close and unavailable-ad behavior.
- `test/ads_app_lifecycle_test.dart`: root-to-service lifecycle forwarding
  without displaying ads on resume. The period-selection regression now uses
  Flutter's valid inactive/hidden/paused/hidden/inactive/resumed sequence rather
  than the older invalid direct paused-to-resumed test shortcut.
- `test/ads_integration_test.dart`: the REAL `ManagedAdService` and `AdPolicy`
  behind the actual pages, only the native SDK boundary faked. Result marks
  daily eligibility for the next free reading and History; the first reading's
  History branch stays clean; History before today's first reading stays
  clean; mode/category/period unlock only from the earned callback (missing,
  failed and unearned ads unlock nothing; a duplicate earned unlocks once);
  bonus analysis is exempt; rapid taps and route disposal queue nothing.
- Existing quota, completion, option-lock and analytics regressions remain.
- `test/ump_form_recovery_test.dart`: production callback-to-outcome mapping,
  startup/privacy form failure and recovery, permission checks, retry spacing,
  thrown errors, pending/late forms and no automatic fullscreen ad display.
- `test/banner_ad_controller_test.dart`: real coordinator permission, initial
  retry/watchdog, hidden/background/fullscreen behavior, late sizing/callbacks,
  privacy invalidation, banner-overlay guard and per-refresh paid telemetry.
- `test/banner_ad_slot_test.dart`: real Home/Reveal/Loading/Result navigation,
  covered routes/modal sheets, reuse, resize and 360dp safe-area/CTA separation
  across all eight app languages. Native banner rendering is explicitly faked.
- `test/banner_ad_adapter_test.dart`: production adaptive request/callback
  mapping and native handle view/size/deferred-disposal contract. The platform
  channel/native ad is faked; this is not physical-device evidence.

Banner follow-up verification, 2026-10-26, from `mobile_app/`:

- `banner_ad_controller_test.dart`, `banner_ad_slot_test.dart`,
  `banner_ad_adapter_test.dart`: **38 passed**. Eight locale layout checks use
  a genuine 360dp viewport and 24dp bottom system inset.
- Final full suite, all 84 current `*_test.dart` files passed explicitly to
  Flutter: **1,347 passed, 0 failed** (2m27s); no tests disabled or skipped.
  A previous discovery run passed 1,347 tests but failed loading a transient
  `_codex_free_cooldown_probe_test.dart`, already absent on inspection. This
  task did not create/delete that file. The final file-list run avoids a
  moving discovery list and is the final verification result.
- `flutter analyze`: **No issues found**. Format check on all 12 changed Dart
  source/test files: **0 changed**. `git diff --check`: clean.
- Engine, local formulas, quota controller, dependencies and native manifests
  are unchanged. Existing dirty branding/icon assets are preserved.
- No physical-device ad rendering, fill, paid delivery or UMP UI was tested.
  No real IDs/account settings, APK build, commit or push were added by this task.

UMP P2 recovery follow-up verification, 2026-10-26, from `mobile_app/`:

- New regression file: **11 passed**, including production callback mapping,
  failed initial/privacy form recovery, permission gating and pending forms.
- Targeted `ump_form_recovery_test.dart`, `ad_runtime_test.dart`,
  `ads_integration_test.dart`, `rewarded_ad_flow_test.dart`: **62 passed**.
- `flutter test --reporter expanded`: **1,309 passed, 0 failed** (4m08s).
- `flutter analyze`: **No issues found** (15.4s).
- Format check on all five changed Dart files: **0 changed, exit 0**.
- No formula, quota, UI, real ad ID, dependency or native-manifest changes.
  This verifies the coordinator/adapter contract with SDK-boundary fakes,
  not real UMP UI or physical-device delivery. No APK build or push performed.

Review follow-up (TASK B3), 2026-10-26, from `mobile_app/`:

- `flutter analyze`: **No issues found**.
- Ads tests (the four files above plus `ads_integration_test.dart`,
  `--reporter expanded`): **58 passed, 0 failed**.
- `flutter test --reporter expanded`: **1,298 passed, 0 failed** (3m45s).
- `dart format --output=none --set-exit-if-changed` on the 19 Dart files
  changed by B3: **0 changed**. `git diff --check`: clean.
- Mutation check: each fix was broken on purpose (wrapper identity, save
  failure as dismissal, update failure treated as refusal, a timer releasing
  the form guard, no resume recovery, bonus analysis showing an ad, protected
  History ignored, CTA unlocking an option). All eight were caught by the new
  tests; every file was restored and checksum-verified.

Earlier verification of the original implementation, 2026-10-26:

- `flutter test --reporter expanded`: **1,276 passed, 0 failed** (2m32s).
- `flutter analyze`: **No issues found** (6.7s).
- `dart format --output=none --set-exit-if-changed` on the 21 changed Dart
  source/test files: **0 changed, exit 0** after the final format pass.
- `git diff --check`: clean. Engine/formulas/quota implementation/pubspec and
  native manifests have no diff from this task. Existing dirty branding/icon
  assets were preserved and not included as ads work.
- Ads-focused coverage is 36 tests across the four files above (34 new and
  two updated existing interstitial tests). The full suite includes them.

Two missing Chinese locale-alias entries found by the first full run were
fixed and localization tests rerun. A subsequent full run caught the old
invalid lifecycle test sequence described above; it was corrected without
weakening its period-expiry assertions. The final full run passed all tests.

These tests inject an SDK backend; they do NOT prove native display, UMP UI,
network fills, clicks or paid callbacks work on a physical device.

## Still required before production

Real AdMob app/ad unit IDs, privacy-message/account configuration, native
Android tests (including offline, click-out/resume, long ads, no reward,
rotation/background and repeated interactions), native banner QA and Play
policy review. History-entry interstitials remain a policy/UX risk; a thirty-
second gap does not prove compliance or guarantee store acceptance. No build,
commit or push is implied by this document.

SDK references used for implementation: [interstitial lifecycle](https://developers.google.com/admob/flutter/interstitial),
[rewarded callbacks](https://developers.google.com/admob/flutter/rewarded),
[UMP consent gating](https://developers.google.com/admob/flutter/privacy).
Banner references: [Flutter banners](https://developers.google.com/admob/flutter/banner),
[AdMob refresh configuration](https://support.google.com/admob/answer/3245199?hl=en).
