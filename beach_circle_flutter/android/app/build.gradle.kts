import com.android.build.gradle.internal.cxx.configure.gradleLocalProperties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // 🔥 Firebase Google Services
    id("com.google.gms.google-services")
    // Flutter Gradle plugin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.beach_circle_flutter"

    // 🔹 Explicit compile/target SDK so Gradle stops complaining
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.beach_circle_flutter"
        minSdk = flutter.minSdkVersion
        targetSdk = 35

        // Basic versioning; we can later hook this to Flutter if you want
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            // OFF for safety
            isMinifyEnabled = false
            isShrinkResources = false
            
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// Tell Flutter where the Dart code is
flutter {
    source = "../.."
}

// 🔥 Firebase Android libs via BoM
dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-firestore-ktx")
    implementation("com.google.firebase:firebase-analytics-ktx")
}
