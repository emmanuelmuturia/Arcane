plugins {
    alias(notation = libs.plugins.androidApplication)
    alias(notation = libs.plugins.kotlinAndroid)
    alias(notation = libs.plugins.compose.compiler)
}

android {
    namespace = "emmanuelmuturia.arcane.android"
    compileSdk = 35
    defaultConfig {
        applicationId = "emmanuelmuturia.arcane.android"
        minSdk = 24
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }
    buildFeatures {
        compose = true
    }
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
        }

        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation(dependencyNotation = projects.commons)
    implementation(dependencyNotation = libs.compose.ui)
    implementation(dependencyNotation = libs.compose.ui.tooling.preview)
    implementation(dependencyNotation = libs.compose.material3)
    implementation(dependencyNotation = libs.androidx.activity.compose)

    implementation(dependencyNotation = libs.google.fonts)

    debugImplementation(dependencyNotation = libs.compose.ui.tooling)
}