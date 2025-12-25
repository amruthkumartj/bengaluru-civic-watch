// android/app/build.gradle.kts

import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Load properties from local.properties
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

android {
    namespace = "in.fixmyooru.app.fixmyooru"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    val googleMapsApiKey: String? = project.findProperty("google.maps.api.key") as String?

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            // Securely load release key properties from local.properties
            storeFile = file(localProperties.getProperty("flutter.signing.config.release.storeFile"))
            storePassword = localProperties.getProperty("flutter.signing.config.release.storePassword")
            keyAlias = localProperties.getProperty("flutter.signing.config.release.keyAlias")
            keyPassword = localProperties.getProperty("flutter.signing.config.release.keyPassword")
        }
        // Note: The 'debug' config is often implicitly defined by Android Studio/Flutter
        // or by a separate file, so we primarily focus on defining the 'release' config here.
    }

    defaultConfig {
        applicationId = "in.fixmyooru.app.fixmyooru"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["googleMapsApiKey"] = googleMapsApiKey ?: ""
    }

    buildTypes {
        release {
            // REPLACE the original signingConfig.getByName("debug") with the new 'release' config
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}