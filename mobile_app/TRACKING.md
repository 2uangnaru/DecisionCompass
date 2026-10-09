# AstraCue — minimal Android analytics

Implemented 2026-10-09. Firebase Analytics is optional and separate from the
offline reading engine. No ads, billing, Crashlytics, Remote Config, account,
server or formula changes are included.

## Current connection status

There is **no real Firebase project configuration in this checkout**. Default
builds use a no-op sink and deactivate the native SDK through the merged Android
manifest. Instrumentation and consent are testable, but these builds send
**no telemetry**. A saved opt-in alone does not establish a Firebase connection.
Device-to-Firebase receipt and dashboard reports remain unverified until the
configuration below is supplied. Never manufacture configuration to clear this
checklist.

## Consent and privacy

- Off by default. An optional switch on Welcome allows opt-in; the same switch
  is available at the bottom of Home's gear > shield > Responsible Use sheet.
  Safety agreement and analytics consent are independent. Declining never
  restricts readings. Copy is translated in all seven supported languages.
- Preferences use `usage_analytics_consent_v1`. Withdrawal gates custom events
  immediately and invalidates queued events. No pre-consent custom events are
  buffered or replayed. An in-flight event already dispatched before withdrawal
  cannot be recalled. SDK-managed delivery of previously collected events is
  distinct from our custom dispatch queue.
- Default native analytics storage and all advertising consents are denied.
  Collection is initially disabled. Advertising identifier collection and
  automatic Activity screen reporting are disabled; both advertising-ID
  permissions (`AD_ID` and `ACCESS_ADSERVICES_AD_ID`) are removed.
  Previously granted SDK consent/collection settings can persist between launches;
  in configured builds the Dart controller reconciles them with the saved choice.
- Custom payloads contain only the fixed parameters below. No name, birth date,
  birth time/country, coordinates, timezone, profile, chart, readingKey,
  inputSnapshot, percentage, free-form text, raw exception or stack is submitted.
  There is no custom `setUserId` or profile-derived user property.
- Firebase/GA4 can collect its own pseudonymous app-instance identifiers,
  sessions/engagement, app/version, device/OS, language and approximate geographic
  information when enabled. This is not a promise of anonymity. Review the SDK's
  published data-disclosure guidance and project settings before release; update
  the actual Privacy Policy and Play Data safety form. These technical controls
  do not establish legal compliance by themselves.

## Event contract

| Event | Trigger | Parameters | Deduplication |
|---|---|---|---|
| `onboarding_started` | First displayed onboarding with consent, or opt-in while that flow is visible | none | Once per flow instance; no rebuild events |
| `onboarding_completed` | Initial profile repository save returns successfully | none | Existing submit lock; no profile-edit events |
| `reading_started` | Loading constructs/validates a live request and starts a calculation | `decision_mode`, `category`, `time_period`, `ui_language` | One per guarded attempt; retry is a new attempt |
| `reading_completed` | First frame of the new generated Result page | same + `elapsed_ms` | Attempt settles once; History replay excluded |
| `reading_failed` | A started calculation attempt settles in an error view | `decision_mode`, `category`, `time_period`, `error_kind` | Attempt settles once; no exception text |
| `history_opened` | First displayed frame of each History page entry | none | No rebuild/retry events |
| `share_requested` | Result's share action invokes platform sharing | `source`: `generated` or `history` | Share-in-flight guard; not a successful-share claim |
| `language_changed` | Successful persistence of a different manually selected UI language | `previous_language`, `new_language` | Same-language taps and failed saves excluded |

Mode/category/period values are existing engine wire enums; language values are
the supported BCP-47 tags. `elapsed_ms` uses a monotonic Stopwatch from Loading
attempt start to the new Result's first frame, including context resolution,
the loading ritual and aperture pre-transition delay. It excludes the earlier
360ms Reveal press animation. It is not engine-only compute latency.

No completion is emitted if consent was absent at attempt start, or if it was
withdrawn/re-enabled during the attempt. Leaving Loading before a result means
no completion. Failures before a validated request exists (for example a closed
period or context capture failure) are not calculation-start/failure events.
First-time safety cancellation also generates no reading event.

The SDK manages `first_open`, `session_start` and engagement; we do not manually
duplicate them. No manual screen-view instrumentation is included in this slice.
The automatic birth-country language default is not a manual language event.

## Connect a real Firebase project

1. In Firebase Console create/select the owner's project and enable Google
   Analytics. Choose the intended reporting timezone and retention settings.
2. Register the Android app with its **actual build applicationId**, currently
   `com.decisioncompass.decision_compass`. Do not change the applicationId as
   part of analytics setup; re-register if the owner later changes it.
3. Download the genuine `google-services.json` into
   `mobile_app/android/app/google-services.json`. It is locally ignored by Git.
   Never paste service-account credentials or signing secrets into the app.
4. The project already conditionally applies Google Services plugin 4.4.4 when
   that file exists. No JSON means ordinary APK builds remain valid.
5. From `mobile_app/`, build with:

   ```powershell
   flutter build apk --debug --dart-define=FIREBASE_ANALYTICS_ENABLED=true
   ```

   Use the same define for an intended analytics-enabled release build. Without
   it the Dart sink is no-op and native collection is deactivated, even if JSON
   exists. Without JSON the manifest remains deactivated as well.
6. Install the enabled build on an Android test device. Leave consent OFF first,
   confirm no custom events, then explicitly turn it ON and exercise the flows.
7. Enable DebugView:

   ```powershell
   adb shell setprop debug.firebase.analytics.app com.decisioncompass.decision_compass
   ```

   Inspect Firebase Console > Analytics > DebugView for exact event names and
   parameters, rapid taps/retries, History replay and consent withdrawal.
   Finish with:

   ```powershell
   adb shell setprop debug.firebase.analytics.app .none.
   ```

   Configure a developer-traffic filter in GA4; DebugView alone should not be
   assumed to exclude test traffic from production reporting/export.

## Dashboard setup (external, not yet performed)

GA4 Admin > Custom definitions: create event-scoped dimensions for
`decision_mode`, `category`, `time_period`, `ui_language`, `error_kind`, `source`,
`previous_language`, `new_language`. Register `elapsed_ms` as an event-scoped
custom metric with millisecond units. Registration does not backfill past data.

Use Firebase/GA4 active-user and engagement reports for DAU/WAU/MAU. Build user-
based funnel explorations for onboarding start > completion and reading start >
completion. Break reading events down by mode/category/period/UI language.
For operational attempt failure rate use `reading_failed / reading_started`
event counts for the same reporting scope; unmatched/abandoned attempts are a
separate non-completion population. Do not call this a crash rate.

Use acquisition/cohort explorations for D1/D7/D30 return-to-app retention, and
separately return-to-reading cohorts if desired. Define the cohort start and
reporting timezone consistently; do not fabricate D1/D7 events on the client.
Late opt-in and consent reset affect observable acquisition/cohorts. Analytics
users are app instances, not verified people, and opt-in data is not the whole
installed-user population. Use Play Console for store downloads, not custom
event counts. Allow the cohort time to mature before judging D7/D30.

Count unique users for user conversion, events for actions/attempts; users can
make multiple readings. Share-request rate is not confirmed outbound shares.
History engagement can use unique History viewers / active analytics users.
Normal reports may be delayed; use DebugView for instrumentation validation.

## Verification

Local unit/widget tests exercise fixed payloads, consent persistence, refusal,
withdrawal, queue invalidation, retries, rebuilds, historical Result exclusion,
share deduplication and consent copy at 360dp/1.5x across all seven languages.
These are not proof of production delivery. No Firebase Console was configured
and no real events have been observed in DebugView during this implementation.

Executed locally on 2026-10-09:
- Dedicated analytics tests: 21 passed.
- Full Flutter suite: 1,132 passed, zero failures.
- After final background-startup/consent-entry changes: analytics plus
  Responsible Use tests re-run, 22 passed; final `flutter analyze` clean.
- Final `flutter build apk --debug`: succeeded, without Firebase JSON/define.
- Merged debug manifest: native collection deactivated `true`, collection
  enabled `false`, four consent defaults `false`; neither advertising-ID
  permission is present. No calculation-engine, local-engine or iOS files changed.
- No physical-device install, visual review, or Firebase delivery verification.

Build tooling downloaded Android SDK Platform 34, required by the installed
plugins, in addition to the existing toolchain. Flutter reports a future
built-in-Kotlin migration warning for firebase_core/firebase_analytics and
flutter_timezone; it did not prevent the debug build. No plugin code was patched.

Official references:
- https://firebase.google.com/docs/analytics/flutter/get-started
- https://firebase.google.com/docs/analytics/flutter/events
- https://firebase.google.com/docs/analytics/debugview
- https://developers.google.com/tag-platform/security/guides/app-consent?platform=android
