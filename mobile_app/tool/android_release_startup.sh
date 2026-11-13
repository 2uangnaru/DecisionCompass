#!/bin/bash
set -euo pipefail
mkdir -p diagnostic/evidence
package=com.astracue.cosmicdecisions
activity=com.decisioncompass.decision_compass.MainActivity

# A disposable CI key only: this is diagnostic installation, never store upload.
keytool -genkeypair -keystore diagnostic/test.jks -storepass android -keypass android \
  -alias diagnostic -dname "CN=CI diagnostic" -keyalg RSA -validity 2 -noprompt
java -jar diagnostic/bundletool.jar validate --bundle=diagnostic/app-release.aab
java -jar diagnostic/bundletool.jar dump manifest --bundle=diagnostic/app-release.aab \
  > diagnostic/evidence/manifest.xml
java -jar diagnostic/bundletool.jar build-apks --bundle=diagnostic/app-release.aab \
  --output=diagnostic/app.apks --connected-device --ks=diagnostic/test.jks \
  --ks-pass=pass:android --ks-key-alias=diagnostic --key-pass=pass:android
java -jar diagnostic/bundletool.jar install-apks --apks=diagnostic/app.apks
adb logcat -c
adb shell am start -W -n "$package/$activity" > diagnostic/evidence/launch.txt 2>&1 || true
# This bounded delay observes native startup / the first Flutter route.
sleep 20
adb logcat -d -v threadtime > diagnostic/evidence/logcat.txt
adb shell pidof "$package" > diagnostic/evidence/pid.txt || true
adb shell dumpsys activity activities > diagnostic/evidence/activities.txt
adb exec-out screencap -p > diagnostic/evidence/screen.png
adb shell uiautomator dump /sdcard/startup.xml > diagnostic/evidence/ui-dump.txt 2>&1 || true
adb pull /sdcard/startup.xml diagnostic/evidence/ui.xml || true
cat diagnostic/evidence/launch.txt
if grep -E 'FATAL EXCEPTION|Fatal signal|Unhandled Exception|Unable to start activity|Unable to instantiate activity' diagnostic/evidence/logcat.txt; then
  echo "Startup crash detected in release split APK installation."
  exit 1
fi
if [[ ! -s diagnostic/evidence/pid.txt ]]; then
  echo "App process did not survive startup."
  tail -n 150 diagnostic/evidence/logcat.txt
  exit 1
fi
if ! grep -F "$package" diagnostic/evidence/ui.xml >/dev/null; then
  echo "App UI was not visible after launch; inspect screenshot and logcat."
  exit 1
fi
echo "Release split APK process and first UI survived startup."