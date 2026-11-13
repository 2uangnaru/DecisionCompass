# Android release startup crash — verified fix, 2026-11-13

Branch: `android`. App fix commit: `4246a1242ebf2b421d5cab8317264c40171ffe29`.
Application ID: `com.astracue.cosmicdecisions`; release version: `0.1.0+11`.

## Reproduction and root cause

The owner reported that the closed-test build installed from Google Play immediately
returned to the Store when Open was tapped. The supplied four-second video shows a
brief native splash and return to Google Play.

The unchanged application at `a9a5cfd` (diagnostic-only commit `6792169`) was built
as a minified release AAB, converted with official bundletool 1.18.3 into connected-device
split APKs, installed and launched on an API 35 x86_64 emulator. Startup crashed before
MainActivity/Flutter could display the app:

```text
Unable to get provider androidx.startup.InitializationProvider
Failed to create an instance of androidx.work.impl.WorkDatabase
```

Baseline run:
https://github.com/2uangnaru/DecisionCompass/actions/runs/43399142511

The local original v10 AAB passed bundletool structure validation. Its R8 mapping
kept `androidx.work.impl.WorkDatabase_Impl`'s class name, but `usage.txt` explicitly
listed `public void <init>()` as removed. Room 2.2.5's old consumer rule retains
database classes without retaining the constructor used through reflection.
AndroidX WorkManager initializes from a content provider before the Flutter UI;
failure here terminates the process immediately. A structurally valid/signed AAB
and passing Dart widget tests cannot detect that failure.

## Minimal fix

- App release config adds `proguardFiles("proguard-rules.pro")`.
- The new app rule preserves only Room database classes and no-argument constructors:

```proguard
-keep class * extends androidx.room.RoomDatabase {
    <init>();
}
```

- Version code increases from 10 to 11 so Play accepts it as an update.
- R8/resource optimization and WorkManager initialization remain enabled.
  No dependency upgrades, broad SDK keep rules, UI/UX, formula, ads/VIP enablement,
  permissions, profile/history migrations or iOS changes were made.

The resulting mapping now includes `WorkDatabase_Impl.<init>()`; that constructor
is no longer in the removed-member list.

## Verification actually completed

Fixed run:
https://github.com/2uangnaru/DecisionCompass/actions/runs/43401217640

- Release AAB build: success with Flutter 3.47.5 / Dart 3.13.4 and Java 17.
- API 24 (Android 7) and API 35 (Android 15), x86_64 emulators: **both passed**.
- Tested connected-device split APK installation from the minified release AAB,
  not a standalone debug APK. After launch the process remained alive and logcat
  contained no fatal exception/native fatal signal/unhandled Dart exception.
- Screenshots were opened and visually checked: both show the real AstraCue
  onboarding screen, language selector and Continue button, beyond native splash.
- Local upload-key-signed release build: success (545.4 seconds).
- Official bundletool validation: exit 0; package/version confirmed as above.
- JAR signature verification: `jar verified`. The self-signed upload certificate's
  PKIX trust warning is expected and is not a failed content-signature check.
- Upload certificate SHA256 matches the original v10 AAB exactly:
  `F6:16:2E:2D:99:14:B9:3B:81:BB:A9:80:B7:30:51:FF:D2:D9:95:38:7E:09:A6:8C:A8:58:0F:61:02:C6:2F:CA`.

No full Flutter suite was rerun: the change is native release optimization, and
the regression check exercises actual native release startup.

The cloud diagnostic AAB uses a disposable CI/debug key for installation; it is
**not the owner-signed upload file**. Use the local signed artifact below for Play.

## Artifact to upload to the closed-test track

On the old Windows workspace, the signed file was copied to:

```text
C:\Users\ADMIN\Documents\Codex\2026-09-18\b-n-l-m-t-chuy\mobile_app\build\app\outputs\bundle\release\AstraCue-v11-startup-fix.aab
```

Size: 101,825,568 bytes.
SHA256: `d25183b1e22a911a2b702eef7760dbaf572354edba215eba43fba29a75f99cfa`.

The source checkout's original build is also at
`mobile_app/build/app/outputs/bundle/release/app-release.aab` in the Android
worktree. Its `AstraCue.aab` filename, if still present, may be the **old v10**;
do not upload an old renamed file by mistake.

Local evidence/logs are under `outputs/android-startup-diagnostic/` in the
Documents workspace; local build log is
`mobile_app/build/android-startup-fix-v11-build.log` in the Android worktree.
These and the AAB are local build artifacts, not committed signing material.

## Remaining release action and limits

Upload versionCode 11 into the existing Google Play closed-test app and roll it
out to the same testers. Have them update from Play and confirm the installed
version is 11. This task did not upload, roll out or approve a Play release.

The before/after native startup regression is verified on emulators. There is
no new physical ARM device or Google Play delivery test of v11 yet, nor a claim
that every later app flow or device-specific problem has been tested. The
on-device reproduction supplied by the owner was of the old broken release.

The Android branch already contains a release keystore and key.properties
locally; they are ignored and were not printed, modified or pushed. Keep a
separate secure backup. Do not copy signing secrets into a public handoff/CI log.

Android checkout used:
`C:\Users\ADMIN\.gemini\antigravity\worktrees\b-n-l-m-t-chuy\audit_app_improvements`.
The Documents workspace remains on `codex/ios`; its dirty/untracked files were
preserved, and no iOS changes were merged into Android.