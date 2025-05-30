plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.logicbloom.pertukekem"
    compileSdk = 35
    ndkVersion = "27.2.12479018"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.logicbloom.pertukekem"
        targetSdk = 35
        minSdk = 23
        versionCode = 1
        versionName = "0.1.0-alpha"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
  implementation(platform("com.google.firebase:firebase-bom:33.14.0"))
  implementation("com.google.firebase:firebase-analytics")
}


flutter {
    source = "../.."
}
