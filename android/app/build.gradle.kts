import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val isReleaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}

if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { stream ->
        keystoreProperties.load(stream)
    }
} else if (isReleaseTaskRequested) {
    throw GradleException(
        "Release signing requires android/key.properties. " +
            "Copy android/key.properties.example and enter the upload-keystore values.",
    )
}

fun requiredSigningProperty(name: String): String =
    keystoreProperties.getProperty(name)?.takeIf(String::isNotBlank)
        ?: throw GradleException("Missing or empty release signing property: $name")

android {
    namespace = "com.matsumotoboundary.constructioncalc"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.matsumotoboundary.constructioncalc"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = requiredSigningProperty("keyAlias")
                keyPassword = requiredSigningProperty("keyPassword")
                val releaseStoreFile = rootProject.file(requiredSigningProperty("storeFile"))
                if (isReleaseTaskRequested && !releaseStoreFile.isFile) {
                    throw GradleException(
                        "Release upload keystore was not found: ${releaseStoreFile.path}",
                    )
                }
                storeFile = releaseStoreFile
                storePassword = requiredSigningProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
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

dependencies {
    implementation("androidx.work:work-runtime:2.12.0")
}
