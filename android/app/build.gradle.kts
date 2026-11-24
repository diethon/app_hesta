import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}
val hasReleaseSigning = keystorePropertiesFile.exists()

android {
    namespace = "com.syna.smarthome"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // flutter_local_notifications yêu cầu desugaring (Java 8+ time APIs)
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.syna.smarthome"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appLabel"] = "Hesta"
        manifestPlaceholders["usesCleartextTraffic"] = "false"
        manifestPlaceholders["networkSecurityConfig"] = "@xml/network_security_config"
        manifestPlaceholders["appLinkHost"] = "app.syna.local"
    }

    flavorDimensions += "environment"
    productFlavors {
        create("development") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            manifestPlaceholders["appLabel"] = "Hesta Dev"
            manifestPlaceholders["usesCleartextTraffic"] = "true"
            manifestPlaceholders["networkSecurityConfig"] = "@xml/network_security_config_dev"
            manifestPlaceholders["appLinkHost"] = "dev.syna.local"
        }
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            manifestPlaceholders["appLabel"] = "Hesta Staging"
            manifestPlaceholders["usesCleartextTraffic"] = "false"
            manifestPlaceholders["networkSecurityConfig"] = "@xml/network_security_config"
            manifestPlaceholders["appLinkHost"] = "staging.syna.local"
        }
        create("production") {
            dimension = "environment"
            manifestPlaceholders["appLabel"] = "Hesta"
            manifestPlaceholders["usesCleartextTraffic"] = "false"
            manifestPlaceholders["networkSecurityConfig"] = "@xml/network_security_config"
            manifestPlaceholders["appLinkHost"] = "syna.example.com"
        }
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// Tự động chạy adb reverse tcp:8080 tcp:8080 mỗi khi build/chạy app trên thiết bị thật
tasks.matching {
    it.name.contains("DevelopmentDebug", ignoreCase = true) || it.name.startsWith("assembleDevelopment")
}.configureEach {
    doFirst {
        try {
            val adb = android.adbExecutable
            if (adb.exists()) {
                project.exec {
                    commandLine(adb.absolutePath, "reverse", "tcp:8080", "tcp:8080")
                    isIgnoreExitValue = true
                }
            }
        } catch (_: Exception) {}
    }
}

