# Decision Compass Mobile

Flutter vertical-slice prototype for iOS and Android. The current build uses mock
reading data so product flow and motion can be validated before connecting the
Node calculation engine.

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
- Mock history

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

## Not connected yet

- Real location permission and timezone resolver
- Node calculation engine/API
- Persistent profile/history
- Ads, IAP and subscription
- Production analytics, localization and store assets
