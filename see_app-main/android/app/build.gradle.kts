plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Add the Google services Gradle plugin
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.see_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // Signing configuration for release builds
    signingConfigs {
        create("release") {
            // These values should be provided through environment variables or a secure keystore
            // For CI/CD pipeline, you would inject these values securely
            // For local development, you can create a signing properties file (not committed to git)
            storeFile = file("../keystore/release-keystore.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "android"  // Fallback for development
            keyAlias = System.getenv("KEY_ALIAS") ?: "upload"  // Fallback for development
            keyPassword = System.getenv("KEY_PASSWORD") ?: "android"  // Fallback for development
        }
    }

    defaultConfig {
        applicationId = "com.example.see_app"
        minSdk = 23  // Updated from flutter.minSdkVersion (21) to meet Firebase Auth requirements
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Required for Firebase Firestore
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Use the release signing configuration
            signingConfig = signingConfigs.getByName("release")
            
            // Enable minification and code shrinking
            isMinifyEnabled = true
            isShrinkResources = true
            
            // Use the default Android proguard rules
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.12.0"))
    
    // Add Analytics
    implementation("com.google.firebase:firebase-analytics")
    
    // Add required Firebase products without specifying versions
    // When using the BoM, Firebase library versions are managed automatically
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    
    // For multidex support
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}