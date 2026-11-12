import java.io.FileInputStream
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// No fabricated Firebase project: ordinary builds still work without JSON.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

val decodedDartDefines: Map<String, String> = (project.findProperty("dart-defines") as? String)
    ?.split(",")
    ?.mapNotNull { encoded ->
        if (encoded.isBlank()) return@mapNotNull null
        val raw = String(Base64.getDecoder().decode(encoded), Charsets.UTF_8)
        val idx = raw.indexOf('=')
        if (idx <= 0) null else raw.substring(0, idx) to raw.substring(idx + 1)
    }
    ?.toMap()
    ?: emptyMap()

val analyticsRequested = decodedDartDefines["FIREBASE_ANALYTICS_ENABLED"] == "true"
val adsRequested = decodedDartDefines["ADS_ENABLED"] == "true"
val testAdmobAppId = "ca-app-pub-3940256099942544~3347511713"
val admobAppId = decodedDartDefines["ADMOB_ANDROID_APP_ID"]
    ?.takeIf { it.isNotBlank() }
    ?: testAdmobAppId
val customApplicationId = decodedDartDefines["ANDROID_APPLICATION_ID"]
    ?.takeIf { it.isNotBlank() }
    ?: "com.decisioncompass.decision_compass"

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

if (adsRequested && admobAppId == testAdmobAppId) {
    val hasReleaseTask = gradle.startParameter.taskNames.any {
        it.contains("Release", ignoreCase = true)
    }
    if (hasReleaseTask) {
        throw GradleException(
            "ADS_ENABLED=true in a release build requires --dart-define=ADMOB_ANDROID_APP_ID=<production_app_id>."
        )
    }
}

android {
    namespace = "com.decisioncompass.decision_compass"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Native SDKs are entirely deactivated in unconfigured/default builds,
        // including before Dart starts and regardless of prior SDK consent.
        manifestPlaceholders["analyticsDeactivated"] =
            (!analyticsRequested || !file("google-services.json").exists()).toString()
        manifestPlaceholders["admobAppId"] = admobAppId
        // Override with --dart-define=ANDROID_APPLICATION_ID=com.publisher.astracue
        // once the publisher supplies their Play Console package identifier.
        applicationId = customApplicationId
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")
                    ?.trim()
                    ?.takeIf { it.isNotEmpty() }
                    ?.let { path -> file(path).takeIf { it.exists() } ?: rootProject.file(path) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Picks up mobile_app/android/key.properties when present; falls back
            // to debug keys only when key.properties is absent during dev testing.
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
        }
    }

    if (!adsRequested) {
        sourceSets.getByName("release").manifest.srcFile("src/noAds/AndroidManifest.xml")
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Device-wide Action Guidance count that survives reinstall (see
    // lib/data/guidance_lock_store.dart).
    implementation("com.google.android.gms:play-services-auth-blockstore:16.4.0")
}
