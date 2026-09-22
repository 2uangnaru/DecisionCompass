# Decision Compass Mobile

Flutter app for Android and iOS. Android is the current priority. Readings come
from the real Node calculation engine over HTTP — the production flow contains
no mock data.

## Included flow

- Location permission explainer and birth-profile onboarding
- Daily signals and all seven decision modes
- NOW/Morning/Midday/Afternoon/Evening selector
- One-tap ritual
- 4.2–5.2 second six-phase celestial loading sequence
- Double-tap reassurance response during loading
- Zodiac avatar derived from the entered birth date
- Subtle breathing pulse on the Reveal button
- Responsive checks for compact phones, standard phones and 800dp large windows
- Result, Top 2 lucky windows and responsible-use footer
- Placeholder history screen (not yet backed by saved readings)

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

## Calculation API transport

`lib/data/http_reading_repository.dart` is the real `ReadingRepository`
implementation: it POSTs a `ReadingRequest` to `/v1/readings` on the Node API
and parses the reply through `ReadingResponse.fromJson`. It never falls back to
mock data and never retries a failed POST.

**The reading flow is wired end to end.** `main.dart` owns the single
`http.Client`, builds the repository and a `DeviceCurrentContextProvider`, and
passes them down by constructor; no page imports `http` or touches a plugin.
Tapping Reveal records the UTC instant, resolves the device IANA timezone (and
an optional one-shot fix when permission was granted), calls the repository
once, and waits for both the response and the 4.2–5.2s ritual before showing
the real result. A failure shows an in-theme error state — retryable only for
timeout, network and server — and never falls back to a mock reading.

`mock_reading_engine.dart` is retained only for an isolated unit test and
previews; nothing under `lib/` imports it.

### Base URL

There is no built-in default, so a build can never silently target someone
else's server. Supply it at build time:

```powershell
C:\Users\ADMIN\develop\flutter\bin\flutter.bat run --dart-define=DECISION_API_BASE_URL=http://127.0.0.1:8787
```

| Target | Base URL |
|---|---|
| Android emulator | `http://10.0.2.2:8787` |
| iOS simulator, Flutter desktop | `http://127.0.0.1:8787` |
| Physical Android device | `http://127.0.0.1:8787` + `adb reverse` |

For a physical Android device, forward the port instead of exposing the server:

```powershell
adb reverse tcp:8787 tcp:8787
```

The Node API stays bound to `127.0.0.1` and rejects any other bind address —
do not rebind it to `0.0.0.0` to reach a device.

`ReadingApiConfig` rejects an empty or malformed URL, a non-http(s) scheme,
embedded credentials, and any query or fragment. It normalizes trailing slashes,
preserves an explicit port and base path, and never rewrites `http` to `https`.

> **Cleartext HTTP is for local development only.** Production builds must use
> HTTPS. This task does not enable `android:usesCleartextTraffic` in the
> production manifest; local Android network config comes with the UI wiring.

Start the API first (from `calculation-engine`):

```powershell
npm run api
```

## Location: explicit opt-in

The explainer screen is the only place location is ever requested, and the
answer is stored as an immutable `useCurrentLocation` flag on the session
profile:

- **Allow Current Location** — sets the flag true, then asks the OS for
  *foreground* permission. A reading may then include a one-shot fix
  (latitude, longitude, accuracy, capture time) describing the **current**
  position only.
- **Use Device Time Zone Instead** — sets the flag false and requests nothing.
  The reading resolves the IANA device timezone and sends `location: null`.

The flag, not the OS permission state, gates the lookup. When it is false the
location plugin is not consulted at all — not even to read a permission granted
in an earlier session — so opting out cannot be overridden by old consent.
Returning to the explainer and choosing again overwrites the flag, and the last
choice wins. A denied, disabled, timed-out or stale fix degrades to
`location: null` and never blocks a reading. Birth country and birth timezone
are never derived from location.

Only `ACCESS_COARSE_LOCATION` and `ACCESS_FINE_LOCATION` are declared; there is
no `ACCESS_BACKGROUND_LOCATION`.

## Android network policy

- **Debug** enables `android:usesCleartextTraffic="true"` in
  `android/app/src/debug/AndroidManifest.xml` only, so an emulator can reach the
  loopback API at `http://10.0.2.2:8787`.
- **Release and profile** manifests never enable cleartext. Production is
  HTTPS-only.

## Remaining work

- Profile and reading-history persistence (a restart returns to onboarding)
- Real history list/detail from saved snapshots
- Monetization: rewarded ads, entitlement, paywall and subscriptions
- Analytics, crash reporting and remote config
- Internationalization, RTL QA and locale formatting
- Store release work: icons, screenshots, signing, privacy documents
- Traditional profile/convention is still not collected (sent as null; the
  engine reduces coverage rather than guessing)
- iOS: no `NSLocationWhenInUseUsageDescription` yet, so an iOS location request
  will not succeed. iOS location support is **not** complete.
