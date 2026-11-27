plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.sangatechnologies.ride"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.sangatechnologies.ride"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_API_KEY"] = "AIzaSyC6xmUBqo4PtfIKf2iGfX3jnBqfnFXNg3o"
        manifestPlaceholders["appName"] = "Sanga Ride"
    }

    signingConfigs {
        System.getenv("CM_KEYSTORE_PATH")?.let { keystorePath ->
            create("release") {
                storeFile = file(keystorePath)
                storePassword = System.getenv("CM_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("CM_KEY_ALIAS")
                keyPassword = System.getenv("CM_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

val releaseBuildTask = Regex("^(assemble|bundle|package)(.*)Release$")

gradle.taskGraph.whenReady {
    val releaseKey = android.signingConfigs.findByName("release")
    val isReleaseBuild = allTasks.any { it.project == project && releaseBuildTask.matches(it.name) }
    val keystoreMissing = releaseKey == null || releaseKey.storeFile?.exists() != true
    if (isReleaseBuild && keystoreMissing) {
        throw GradleException(
            "Release build stopped: no release keystore. Set CM_KEYSTORE_PATH (an existing file), " +
                "CM_KEYSTORE_PASSWORD, CM_KEY_ALIAS and CM_KEY_PASSWORD. Release builds are never signed with the debug key."
        )
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
