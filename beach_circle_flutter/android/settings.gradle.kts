import java.util.Properties
import org.gradle.api.GradleException

pluginManagement {
    val flutterSdkPath = run {
        val properties = Properties()
        val localPropertiesFile = file("local.properties")
        if (!localPropertiesFile.exists()) {
            throw GradleException("local.properties not found. Run `flutter pub get` in the project root.")
        }
        localPropertiesFile.inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

// 🔥 THIS IS THE NEW PART THAT FIXES THE DOWNLOADS
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "1.8.22" apply false
    id("com.google.gms.google-services") version "4.4.4" apply false
}

include(":app")