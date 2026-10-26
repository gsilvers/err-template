plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The name under the launcher icon. Debug builds add " (debug)".
val appLabel = "Err Template"

android {
    namespace = "io.github.gsilvers.err_template"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Changing this after release makes Android treat it as a different
        // app: no upgrade over the old install, and its data stays behind.
        applicationId = "io.github.gsilvers.err_template"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appLabel"] = appLabel
    }

    // Set by CI when the KEYSTORE_BASE64 secret is configured. Blank counts as
    // absent, so a workflow run without the secret still produces an APK.
    val releaseKeystore = System.getenv("KEYSTORE_PATH")?.takeIf { it.isNotBlank() }

    signingConfigs {
        create("release") {
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
            storeFile = releaseKeystore?.let { file(it) }
            storePassword = System.getenv("STORE_PASSWORD")
        }
    }

    buildTypes {
        debug {
            // A separate app ID lets a debug build sit next to the release
            // you installed from GitHub, instead of clashing with its signature.
            applicationIdSuffix = ".debug"
            manifestPlaceholders["appLabel"] = "$appLabel (debug)"
        }
        release {
            // Use the release keystore when the env vars are present (CI),
            // fall back to debug signing for local `flutter build apk --release`.
            signingConfig = if (releaseKeystore != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
