import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing — loaded from android/key.properties (gitignored). Absent on
// machines without the upload keystore, in which case release falls back to the
// debug key so `flutter run --release` still works locally.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Fail configuration with a pointed message on a partial key.properties instead
// of an opaque NPE from a bare `as String` cast.
fun keystoreProperty(name: String): String =
    keystoreProperties.getProperty(name)
        ?: throw GradleException(
            "android/key.properties is missing '$name' — it must define " +
                "keyAlias, keyPassword, storeFile and storePassword " +
                "for release signing."
        )

android {
    namespace = "ch.fuchsnest.knobelfuchs"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "ch.fuchsnest.knobelfuchs"
        // Fuchsbau baseline: API 26 (adaptive icons).
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperty("keyAlias")
                keyPassword = keystoreProperty("keyPassword")
                storeFile = file(keystoreProperty("storeFile"))
                storePassword = keystoreProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Sign with the upload key when key.properties is present, otherwise
            // fall back to debug so local `flutter run --release` still works.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "WARNING: android/key.properties not found — release " +
                        "artifacts will be DEBUG-SIGNED and rejected by the " +
                        "Play Store. Fine for local `flutter run --release`."
                )
                signingConfigs.getByName("debug")
            }
            // Keep R8 off (knabberfuchs precedent): it strips the
            // reflection-heavy CameraX/ML Kit classes mobile_scanner needs at
            // runtime ("Couldn't start the camera" in release only). The
            // bundle is dominated by music assets anyway. Re-enable only with
            // full keep rules (mobile_scanner, CameraX, drift, …).
            isMinifyEnabled = false
            isShrinkResources = false
        }
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
