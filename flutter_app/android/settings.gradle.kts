import java.util.Properties

pluginManagement {
    val properties = java.util.Properties()
    val localPropertiesFile = file("local.properties")

    require(localPropertiesFile.exists()) {
        "local.properties not found"
    }

    localPropertiesFile.inputStream().use { properties.load(it) }

    val flutterSdkPath = properties.getProperty("flutter.sdk")
        ?: error("flutter.sdk not set in local.properties")

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)

    repositories {
        google()
        mavenCentral()
        maven(url = "https://storage.googleapis.com/download.flutter.io")
    }
}
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    id("com.android.application") version "8.9.1" apply false
    id("com.android.library") version "8.9.1" apply false
    
    // BUMP THIS LINE TO 2.3.10:
    id("org.jetbrains.kotlin.android") version "2.3.10" apply false 
    
    id("com.google.gms.google-services") version "4.4.1" apply false 
}
include(":app")