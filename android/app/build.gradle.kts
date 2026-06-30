import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use(keystoreProperties::load)
}

val googleTestAdMobAppId = "ca-app-pub-3940256099942544~3347511713"
val adIdsSource = rootProject.file("../lib/services/ad/ad_ids.dart").readText()
val productionAdMobAppId = Regex(
    """androidAdMobAppId\s*=\s*'([^']+)'""",
).find(adIdsSource)?.groupValues?.get(1)
val releaseAdMobAppId = productionAdMobAppId
    ?.takeIf { it.startsWith("ca-app-pub-") && !it.contains("YOUR_") }
    ?: googleTestAdMobAppId

android {
    namespace = "com.faryzenstudios.otoparkbulmacasi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.faryzenstudios.otoparkbulmacasi"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["adMobAppId"] = googleTestAdMobAppId
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")
                ?.let(rootProject::file)
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            manifestPlaceholders["adMobAppId"] = releaseAdMobAppId
            if (releaseAdMobAppId == googleTestAdMobAppId) {
                logger.warn(
                    "AdMob production App ID is missing. Release ads will be disabled safely.",
                )
            }
        }
    }
}

flutter {
    source = "../.."
}
