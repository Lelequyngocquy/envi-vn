import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")

    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

val releaseStoreFilePath: String? =
    keystoreProperties.getProperty("storeFile") ?: System.getenv("ENVIVN_KEYSTORE_PATH")
val releaseStorePassword: String? =
    keystoreProperties.getProperty("storePassword") ?: System.getenv("ENVIVN_KEYSTORE_PASSWORD")
val releaseKeyAlias: String? =
    keystoreProperties.getProperty("keyAlias") ?: System.getenv("ENVIVN_KEY_ALIAS")
val releaseKeyPassword: String? =
    keystoreProperties.getProperty("keyPassword") ?: System.getenv("ENVIVN_KEY_PASSWORD")
val hasReleaseSigning =
    !releaseStoreFilePath.isNullOrBlank() &&
        !releaseStorePassword.isNullOrBlank() &&
        !releaseKeyAlias.isNullOrBlank() &&
        !releaseKeyPassword.isNullOrBlank() &&
        file(releaseStoreFilePath).exists()

android {
    namespace = "com.envivn.envivn"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.envivn.envivn"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseStoreFilePath!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                val requireSigning = System.getenv("ENVIVN_REQUIRE_RELEASE_SIGNING") == "true"
                if (requireSigning) {
                    throw GradleException("Missing release keystore configuration (key.properties or ENVIVN_KEYSTORE_* env vars).")
                }
                logger.warn("Release keystore not configured; falling back to debug signing for local verification build.")
                signingConfig = signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
