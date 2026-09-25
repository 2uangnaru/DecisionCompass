# AstraCue: Cosmic Decisions — Mobile

Flutter app for Android and iOS. Android is the current priority. **Readings
are calculated entirely on the device** — the production flow contains no mock
data, no server and no HTTP call.

## Included flow

- Device-timezone explainer and explicit birth-profile onboarding
- Daily signals and all seven decision modes
- NOW/Morning/Midday/Afternoon/Evening selector
- One-tap ritual
- 4.2–5.2 second six-phase celestial loading sequence
- Double-tap reassurance response during loading
- Zodiac avatar derived from the entered birth date
- Subtle breathing pulse on the Reveal button
- Responsive checks for compact phones, standard phones and 800dp large windows
- Result, Top 2 lucky windows and responsible-use footer
- Saved reading history with replay, retry-on-error and result sharing

## Run

```powershell
$env:GIT_CONFIG_COUNT='1'
$env:GIT_CONFIG_KEY_0='safe.directory'
$env:GIT_CONFIG_VALUE_0='C:/Users/ADMIN/develop/flutter'
C:\Users\ADMIN\develop\flutter\bin\flutter.bat pub get
C:\Users\ADMIN\develop\flutter\bin\flutter.bat test
C:\Users\ADMIN\develop\flutter\bin\flutter.bat run
```

If Flutter is later added to PATH, use `flutter` directly.

No `--dart-define` is needed: the calculation engine is bundled in the app.

## Android build

The verified local toolchain uses Android Platform 36, Build-Tools 36.0.0,
NDK 28.2.13676358 and Temurin JDK 17.0.20.1.

```powershell
$env:JAVA_HOME='C:\Users\ADMIN\develop\jdk-17'
$env:ANDROID_HOME='C:\Users\ADMIN\AppData\Local\Android\sdk'
C:\Users\ADMIN\develop\flutter\bin\flutter.bat build apk --debug
```

Debug APK output:

```text
build\app\outputs\flutter-apk\app-debug.apk
```

## Offline local engine

The calculation engine ships **inside the app**. An installed APK produces a
real reading with the network switched off; there is no API base URL, no
`--dart-define`, no localhost and no `adb reverse`.

```text
                       +---------------------------- UI isolate -----+
  Reveal tap --------->| LoadingPage                                 |
                       |   +- ReadingDependencies                    |
                       |        +- CurrentContextProvider            |
                       |        |    flutter_timezone -> IANA id     |
                       |        |    geolocator -> one-shot fix      |
                       |        |       (only if the user opted in)  |
                       |        +- LocalReadingRepository            |
                       |             ReadingRequest --> JSON map     |
                       +------------------+--------------------------+
                                          | Isolate.run (plain maps only --
                                          | no plugin, no file, no socket)
                       +------------------v------- background isolate ---+
                       | lib/local_engine/local_reading_engine.dart      |
                       |                                                 |
                       |  time/       tzdb 2026d, DST folds and gaps     |
                       |  calendar/   solar terms, pillars, almanac  (T) |
                       |  bazi/       four pillars, decade cycle     (B) |
                       |  ziwei/      palaces, stars, horoscope      (Z) |
                       |  astronomy/  VSOP87 + lunar series, aspects (W) |
                       |  numerology/ life path, personal day        (N) |
                       |  astronomy/  lunar phase, Mercury motion    (U) |
                       |      +--> fuse by category -> A and C axes      |
                       |             +--> project by mode -> percentages |
                       |                    +--> sha256 -> readingKey    |
                       +------------------+------------------------------+
                                          | JSON map
                       +------------------v-------------------------+
                       | ReadingResponse.fromJson -> ResultPage      |
                       +--------------------------------------------+
```

Nothing about the contract changed: the engine emits the same JSON shape
`calculation-engine/src/index.d.ts` declares, and the existing `ReadingResponse`
DTO parses it unchanged.

No `--dart-define` is required, because the engine is bundled.

### Size impact of the bundled engine

Measured by building a release APK twice with only `main.dart` swapped between
the development HTTP repository and the local engine:

| Release APK | Size |
|---|---:|
| Without the engine | 55,335,522 B (52.8 MB) |
| With the engine | 57,514,594 B (54.9 MB) |
| **Impact** | **+2,179,072 B (+2.08 MB, +3.9 %)** |

The debug APK grows by about 0.19 MB, since a debug build already carries the
whole kernel snapshot. See `lib/local_engine/LICENSES.md` for the breakdown.

### Parity with the Node engine

`calculation-engine/` remains the mathematical reference. The port is checked
against it rather than against anyone's expectations:

| Test | What it proves |
|---|---|
| `test/local_engine/golden_reading_parity_test.dart` | All 16 real engine fixtures reproduce field for field, **including every `readingKey`** |
| `test/local_engine/edge_readings_parity_test.dart` | 16 whole readings for DST folds and gaps, the date line, quarter-hour offsets, unknown birth hours, elapsed periods and two/one/zero windows |
| `test/local_engine/time_parity_test.dart` | tzdb unpacking, local time, segmentation, birth intervals |
| `test/local_engine/astronomy_parity_test.dart` | Body longitudes to under a microarcsecond |
| `test/local_engine/calendar_parity_test.dart` | Solar terms to the millisecond, lunar dates, pillars |
| `test/local_engine/bazi_parity_test.dart` | Charts, coverage, decade cycle |
| `test/local_engine/ziwei_parity_test.dart` | 112 charts, 1680 horoscope layers, 224 module scores |
| `test/local_engine/offline_guarantees_test.dart` | `main.dart` reaches no HTTP repository and no API config |
| `test/local_engine/offline_flow_test.dart` | The real UI reaches the result page with the real engine |

Every expectation file under `test/local_engine/` is generated by running the
Node engine (`calculation-engine/scripts/port/gen_*.mjs`), so a disagreement is
a port defect by definition.

### What is deliberately *not* bundled

Coordinate-to-timezone geometry. The dataset is 30 MB and ODbL share-alike, so
shipping it is a product and legal decision rather than an implementation
detail. Until that geometry ships, the app never asks for a position fix; it
uses the device's IANA timezone for each reading. The dormant calculation
adapter still has an explicit `zone_lookup_unavailable` fallback for tests and
future integration. See `lib/local_engine/LICENSES.md` for the full reasoning.

### Development-only HTTP transport

`lib/data/http_reading_repository.dart`, `reading_api_config.dart` and
`misconfigured_reading_repository.dart` are **development and test artifacts**.
`main.dart` does not reference them, so they are tree-shaken out of the app, and
`DECISION_API_BASE_URL` has no effect on a production build. They are kept so
the loopback Node API (`npm run api` in `calculation-engine`) stays reachable
while regenerating fixtures or cross-checking the port.

> The `ReadingApiFailureKind.configuration` copy on the error screen still
> mentions that define. It is unreachable in production now that no build can
> be misconfigured, and is left in place so the error-state switches stay
> exhaustive.

### Failure handling

A local failure never fabricates a reading. An input the engine refuses
(`BIRTH_DATE_IN_FUTURE`, `INVALID_IANA_TIMEZONE`, and the rest) becomes a
non-retryable `rejectedRequest`; anything unexpected becomes a retryable
`server` failure. Neither carries the input value, a coordinate, a stack trace
or a formula -- only an app-owned code and sentence.

## Current time and birth country

The app reads the device's IANA timezone at Reveal, without requesting GPS.
`location: null` is sent to the engine even if a legacy profile stored an old
location opt-in. The Android main manifest declares no location permissions.
The user must explicitly choose a birth date and a searchable country of birth;
neither is inferred from current time or location. The birth-country picker is
limited to country codes supported by the bundled timezone database.

## Android network policy

A reading needs no network at all, so nothing in the production flow opens a
socket.

- **Debug** still enables `android:usesCleartextTraffic="true"` in
  `android/app/src/debug/AndroidManifest.xml`, so a developer build can reach
  the loopback API when cross-checking the port. Production never does.
- **Release and profile** manifests never enable cleartext.

### Verifying it offline

```powershell
C:\Users\ADMIN\develop\flutter\bin\flutter.bat build apk --debug
adb install -r build\app\outputs\flutter-apk\app-debug.apk
adb shell cmd connectivity airplane-mode enable
```

Then open the app and take a reading. No `adb reverse`, no server and no
`--dart-define` is involved at any point.

## Remaining work

- Profile editing and export/delete controls for local data
- Monetization: rewarded ads, entitlement, paywall and subscriptions
- Analytics, crash reporting and remote config
- Internationalization, RTL QA and locale formatting
- Store release work: icons, screenshots, signing, privacy documents
- Traditional profile/convention is still not collected (sent as null; the
  engine reduces coverage rather than guessing)
- Coordinate-to-timezone geometry remains out of scope; device timezone is
  used without requesting location (see `lib/local_engine/LICENSES.md`)
