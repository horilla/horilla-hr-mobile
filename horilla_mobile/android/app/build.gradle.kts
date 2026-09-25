import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.cybrosys.horilla_project"
    compileSdk = 36
    // camera_android_camerax, google_mlkit_* and several other plugins all
    // require this NDK; the flutter tool prints the exact version to pin
    // whenever a build mixes an older one in.
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }


    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.cybrosys.horilla_project"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        // From pubspec (version: 2.0.0+12) rather than hardcoded: these had
        // drifted to 1.0.3/9 while pubspec said 1.0.10+11, and a release
        // needs one source of truth. versionCode must only ever increase --
        // check the Play Console before the first upload.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            isShrinkResources = true // This requires isMinifyEnabled = true
        }
        getByName("debug") {
            // Debug builds install alongside the released app instead of
            // replacing it. Same package id would mean uninstalling the real
            // app from a tester's phone -- and a debug build that looks
            // identical to production on the launcher is its own hazard.
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            // The launcher name comes from src/debug/res rather than a
            // resValue, which AGP 9 gates behind a build feature.
        }
    }
}

// Kotlin 2.x removed the kotlinOptions DSL that the inherited config used.
kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_17
    }
}

kotlin {
    jvmToolchain(17)
}

dependencies {
//    implementation("com.regula.face:api:6.1.3163")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("com.google.mlkit:text-recognition:16.0.0")
    implementation("com.google.mlkit:text-recognition-chinese:16.0.0")
    implementation("com.google.mlkit:text-recognition-devanagari:16.0.0")
    implementation("com.google.mlkit:text-recognition-japanese:16.0.0")
    implementation("com.google.mlkit:text-recognition-korean:16.0.0")
    // Add your other dependencies here
}

flutter {
    source = "../.."
}
