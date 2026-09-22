# Decision Compass — Project Handoff

Updated: 2026-09-21

This file is the implementation handoff for any coding agent joining this
repository. Read it before changing code. The product and UX specifications are
in `outputs/`; this file records what is actually implemented versus planned.

## 1. Product definition

Decision Compass is a global mobile app for lightweight, everyday reflection.
The user keeps a choice in mind, selects a binary direction and a time period,
then taps once to receive a deterministic symbolic direction and, for a future
period, up to two favorable time windows.

The app is not a chatbot and does not ask what the decision is about. It asks
only which area of life the choice belongs to: `general`, `love`, `career`,
`money`, `study`, `friends` or `other`. Category changes module weights, Zi Wei
target palaces and the Western body emphasis before the decision-mode
projection; `other` reuses the general formula as an honest fallback while
staying a distinct category. See the 2026-09-22 section of
`calculation-engine/VERIFICATION.md`. It must not claim that its percentages are real-world
probabilities, accuracy, confidence or guaranteed outcomes.

MVP inputs:

- Name, for UI only.
- Birth date.
- Birth time or `unknown`.
- Country of birth. Do not silently use current location as birthplace.
- Traditional profile/convention when needed by the calculation. It may be
  `unspecified`; never infer it from name or country.
- Current UTC instant and current IANA device timezone, captured when Reveal is
  tapped.
- Optional one-shot foreground location. It is for current timezone/region only.
- Decision mode and selected period.

Supported modes:

1. YES / NO
2. ACT / WAIT
3. ADVANCE / RETREAT
4. STAY / GO
5. KEEP / LET GO
6. FORWARD / BACKWARD
7. LEFT / RIGHT

Periods are `now`, `morning`, `midday`, `afternoon`, and `evening`. NOW uses the
instant at Reveal. Other periods return zero, one or two remaining windows for
the selected local period; never silently roll into tomorrow.

Responsible-use scope: everyday reflection only. Do not position results for
medical, emergency, legal, financial, gambling, self-harm, violence, criminal
activity or another person's consent.

## 2. Repository map and sources of truth

- `mobile_app/`: Flutter UI vertical slice. It currently uses mock readings.
- `calculation-engine/`: real deterministic Node.js calculation engine.
- `outputs/Decision_Compass_UX_UI_Spec_v1.md`: target UX, copy, edge cases,
  monetization and safety behavior.
- `outputs/Decision_Compass_MVP_Calculation_Scope.md`: calculation scope and
  input/timezone rules.
- `calculation-engine/README.md`: actual engine behavior and known limits.
- `calculation-engine/src/index.d.ts`: authoritative integration contract.
- `calculation-engine/VERIFICATION.md`: verification scope; currently has stale
  version metadata noted below.
- `outputs/Decision_Compass_Formula_v1.md` and `v2.md`: historical formula work,
  not the final runtime contract. Do not reimplement from these instead of the
  current engine.

If documents conflict with running code, stop and document the discrepancy
before changing calculation behavior.

## 3. What is implemented now

### 3.1 Calculation engine

The Node engine accepts raw profile/current-context inputs and returns a
deterministic result. It uses no AI, no paid API and no random value in the
result path.

Implemented modules:

- Current context and timezone fallback, including DST edge handling.
- Chinese lunar calendar, leap months, 24 solar terms, Can Chi, auspicious day
  classification and 12 day officers.
- BaZi pillars, hidden stems, Ten Gods, element distribution, seasonal support,
  roots, branch relationships and decade cycle when data allows.
- Zi Wei 12 palaces, 14 major stars, selected auxiliary/malefic stars,
  brightness and transformations across configured time layers.
- Western planetary positions and selected natal/transit aspects.
- Numerology: Life Path and personal year/month/day.
- Lunar phase and Mercury direct/stationary/retrograde signal.
- Six-module fusion, data coverage, deterministic reading key and audit fields.
- Seven separate decision-mode projections.
- NOW and future-period calculations with top two mode-specific time windows.
- Unknown-birth-hour scenario handling instead of inventing noon or an hour.

The two fusion axes are `A` (action) and `C` (change). The first label score for
each mode is:

| Mode | Projection |
|---|---:|
| YES / NO | `A` |
| ACT / WAIT | `.85A + .15C` |
| ADVANCE / RETREAT | `.55A + .45C` |
| STAY / GO | `-C` |
| KEEP / LET GO | `.30A - .70C` |
| FORWARD / BACKWARD | `.25A + .75C` |
| LEFT / RIGHT | `-.70A + .30C` |

LEFT/RIGHT is symbolic polarity only: LEFT is receptive/inward; RIGHT is
expressive/outward. It must never be used for physical navigation or safety.

Current test state checked on 2026-09-21: `47/47` Node tests pass.

### 3.2 Flutter prototype

Implemented visual flow:

1. Location explanation screen.
2. Birth profile screen.
3. Home with daily-signal card, seven modes and five periods.
4. One-tap Reveal ritual.
5. 4.2–5.2 second celestial loading animation.
6. Result page with percentages and two mock windows for non-NOW periods.
7. Mock history page.

Implemented UI details:

- Dark mystical theme brightened for readability.
- Responsive max content width of 640 logical pixels.
- Layout smoke-tested at 360x640, 390x844, 412x915 and 800x1280 portrait.
- Production zodiac artwork changes from the entered birth date on onboarding,
  home, ritual and loading screens. The 12 RGBA medallions use the shared
  Celestial Observatory visual system and animate between signs.
- Reveal button has a subtle 1.5-second breathing pulse and respects reduced
  motion.
- Loading shows six narrative phases and eight orbit labels.
- A fast double tap during loading shows one reassurance line, except when
  accessible navigation is active.
- Result colors, percentages, NOW explanation, future-period window cards and a
  responsible-use footer are visually represented.
- Six Flutter tests exist, including zodiac-asset mapping and full-flow portrait
  size checks. Verification on 2026-09-21 passed 6/6 tests with a clean analyzer.
- A debug Android APK has been built previously at
  `mobile_app/build/app/outputs/flutter-apk/app-debug.apk` when build artifacts
  are present locally.

## 4. What is mock or incomplete

The current APK is a visual prototype, not a functional MVP.

### P0 blockers: required for a real end-to-end product

- Flutter does not call the Node engine. `loading_page.dart` calls
  `createMockReading()` from `mock_reading_engine.dart`.
- No engine transport exists: no backend API, local Dart port or native bridge.
- The location buttons only advance the UI. There is no permission request,
  location capture, timezone resolution, denial flow or stale-location handling.
- Android main manifest has no foreground location permissions. It also has no
  production INTERNET permission; INTERNET exists only in debug/profile
  manifests.
- Birth profile is not persisted and is mostly not passed beyond onboarding.
  Only name and derived zodiac sign reach Home.
- `Birth time unknown` is only a switch. There is no time picker when the switch
  is turned off.
- Country list contains only five hardcoded countries and uses display names,
  while the engine expects country codes.
- Traditional profile/convention is not collected.
- Current instant/timezone are not captured at Reveal.
- Daily color, lucky number, energy, greeting, history and all result values are
  hardcoded.
- Loading copy is timer-driven and is not connected to an engine analysis trace
  or API success/failure state.
- No error, retry, offline, insufficient-data, balanced 50/50, elapsed-period,
  one-window or zero-window UI is wired to real data.
- No local database or secure profile storage. Restarting the app returns to
  onboarding and loses everything.

### P1 product features specified but not implemented

- First-reading safety acknowledgement and Responsible Use detail screen.
- Reading cache/snapshot rules, duplicate-reading behavior, cooldown after four
  readings in ten minutes and twelve-reading daily safety cap.
- Rewarded ads, daily free entitlement, unlocked-period state and ad failure
  reconciliation.
- Premium paywall, subscriptions, restore purchases and entitlement state.
- Real history list/detail, seven-day free retention and full premium history.
- Share result; the share icon currently has an empty callback.
- Save result; the button is visual only.
- Profile editing, Settings, delete/export data and active-timezone display.
- Push notification permission and daily/lucky-window/weekly notifications.
- System/Light/Dark theme selector; only dark theme exists.
- Internationalization, RTL QA, locale date/time formatting and global copy
  review. Current UI is English-only.
- Analytics events, attribution, crash reporting, privacy consent and remote
  configuration.

### P2 production and quality work not implemented

- Production app icon, splash, store screenshots, privacy policy and terms.
- Release application ID decision, release signing and Play/App Store pipelines.
- Physical-device Android QA, landscape/foldable/two-pane layouts and iOS QA.
- Comprehensive accessibility audit: 200% text, contrast measurement, screen
  reader order/labels, switch control and large touch targets.
- Unit/widget/golden/integration tests for real engine responses, failures,
  storage, monetization and safety limits.
- Backend security/load/observability, if a backend integration is selected.

## 5. Known calculation limits: do not overclaim

- Automatic traditional Yong Shen/Xi Shen is not implemented. The engine emits
  null and reduces coverage rather than inventing it.
- Not every BaZi special structure/combination or Zi Wei star configuration is
  scored.
- No Ascendant, houses or true solar time because MVP does not require exact
  birthplace coordinates.
- No spatial feng shui, Qi Men or I Ching.
- Calendar convention is the documented Chinese civil-date ruleset, not a fully
  localized Vietnamese/Japanese calendar school.
- Verification establishes deterministic software behavior, not predictive
  validity in the real world.

## 6. Known repository inconsistencies

Resolve these before tagging a release:

- `calculation-engine/src/core.js` reports engine `3.1.0-mvp` and ruleset v4.
- `calculation-engine/package.json`, the beginning of
  `calculation-engine/README.md`, and `calculation-engine/VERIFICATION.md` still
  say `3.0.0-mvp`.
- Do not alter score formulas merely to make old snapshots pass. Update metadata
  and add an explicit migration/version note.
- `.claude/` and `mobile_app/.claude/` are currently untracked local IDE launch
  configuration. Inspect before committing; do not assume they are product code.

## 7. Engine integration contract

Use `calculation-engine/src/index.d.ts` as the exact schema. Minimal example:

```json
{
  "profile": {
    "birthDate": "1998-06-21",
    "birthTime": null,
    "birthCountry": "VN",
    "traditionalProfile": "unspecified",
    "revision": 1
  },
  "context": {
    "instantUtc": "2026-09-21T04:00:00.000Z",
    "deviceTimezone": "Asia/Ho_Chi_Minh"
  },
  "mode": "forward_backward",
  "period": "evening",
  "category": "general",
  "diagnostics": false
}
```

Important result fields:

- `status`: `ready`, `balanced`, `insufficient_data` or `period_elapsed`.
- `winner` and `percentages`.
- `modeScore` and `modeBasis`.
- `dataCoverage`, warnings and birth-data status.
- `readingKey`, engine/ruleset/provider versions and input snapshot.
- `context.timezone`, source, offset and local date.
- `dailyBrief`.
- `luckyWindows` and `windowStatus`.

Never send diagnostics, raw birth data or coordinates to analytics. A
`readingKey` is an identifier, not an authentication secret.

## 8. Recommended implementation sequence

### Milestone A — real reading vertical slice

1. Fix engine version metadata without changing formulas; rerun all Node tests.
2. Decide and document one integration architecture:
   - Recommended fastest MVP: a small owned Node API wrapping
     `createCalculator(profile).calculate(request)`.
   - Alternative: a verified Dart/native port. This is larger because the Node
     engine depends on calendar, Zi Wei, astronomy, timezone and geo datasets.
3. Add immutable Dart DTOs and enum mappings matching `index.d.ts` exactly.
4. Implement profile form completely: real birth-time picker, unknown state,
   ISO country codes and traditional profile/unspecified.
5. Implement one-shot location permission plus device-timezone fallback. Do not
   block readings when location is denied.
6. Capture UTC instant and IANA timezone only when Reveal is accepted.
7. Replace `createMockReading()` with a repository/service interface and real
   engine adapter. Keep a fake adapter only for tests and previews.
8. Drive Result states from actual API response. Save the immutable snapshot.

Milestone A acceptance criteria:

- Two different profiles can produce real, deterministic engine responses.
- Repeating the same reading key returns the same snapshot without rerolling.
- All seven modes map correctly; FORWARD/BACKWARD and LEFT/RIGHT are demonstrably
  not aliases of YES/NO.
- NOW contains no lucky windows. Future periods correctly show two, one, none or
  elapsed state.
- Location denial still yields a reading using the device timezone.
- No mock value appears in a production code path.
- Contract, unit and Flutter integration tests pass.

### Milestone B — persistence and safe product behavior

1. Persist profile revisions, entitlement/day state and reading snapshots.
2. Implement onboarding routing so existing users do not restart onboarding.
3. Implement safety acknowledgement, cooldown and daily cap.
4. Implement history list/detail from saved snapshots.
5. Add retry/offline/error behavior without fabricating a result.
6. Add accessibility and localization foundations before duplicating copy.

### Milestone C — monetization and release readiness

1. Rewarded-ad entitlement and failure reconciliation.
2. Subscription/paywall/restore flow using live store products and localized
   prices; do not hardcode prices in copy.
3. Analytics event plan that excludes sensitive data.
4. Release identifiers/signing, privacy documents, store assets and device QA.

## 9. Suggested first task for Claude

Take Milestone A items 1 and 3 only, unless the user explicitly expands scope:

1. Normalize engine metadata to `3.1.0-mvp` and ruleset v4 in package/docs.
2. Add Dart request/response DTOs and enum serialization that mirror
   `calculation-engine/src/index.d.ts`.
3. Add round-trip fixture tests using committed sanitized engine JSON. Do not
   connect networking yet and do not edit calculation formulas.

Deliverables and acceptance:

- A concise changed-file list.
- Node tests remain 47/47.
- Flutter analyzer and tests pass.
- DTO tests cover every mode, every period and every result/window status.
- Unknown fields from newer server versions do not crash parsing.
- Missing required fields fail with explicit typed errors, not silent defaults.

This task is intentionally isolated so another agent can work on location/profile
UI later without editing the same files.

## 10. Coordination rules

- Run `git status --short` before and after work. Preserve unrelated user edits.
- Do not edit `calculation-engine/src/core.js` formulas without an explicit task.
- Do not call the current Flutter app “integrated” while it imports
  `mock_reading_engine.dart` in the production flow.
- Put engine access behind an interface; UI pages must not construct HTTP or raw
  JSON directly.
- Do not add randomization to results. Randomized loading duration is visual only.
- Do not use current location as birth location/timezone.
- Store UTC instant plus IANA timezone and engine/ruleset/provider versions in
  every saved snapshot.
- Do not rerun old historical readings when formulas change.
- Do not commit secrets, signing keys, machine SDK paths, caches or generated
  build directories.
- When work overlaps another agent, stop and agree on file ownership before
  modifying shared files.

## 11. Local commands

Engine, from `calculation-engine/`:

```powershell
node --test test/*.test.js
node examples/demo.js
node scripts/stress.js
node scripts/check-reference.js
```

Flutter, from `mobile_app/`:

```powershell
$env:GIT_CONFIG_COUNT='1'
$env:GIT_CONFIG_KEY_0='safe.directory'
$env:GIT_CONFIG_VALUE_0='C:/Users/ADMIN/develop/flutter'
C:\Users\ADMIN\develop\flutter\bin\flutter.bat pub get
C:\Users\ADMIN\develop\flutter\bin\flutter.bat analyze
C:\Users\ADMIN\develop\flutter\bin\flutter.bat test
```

Android debug build:

```powershell
$env:JAVA_HOME='C:\Users\ADMIN\develop\jdk-17'
$env:ANDROID_HOME='C:\Users\ADMIN\AppData\Local\Android\sdk'
C:\Users\ADMIN\develop\flutter\bin\flutter.bat build apk --debug
```
