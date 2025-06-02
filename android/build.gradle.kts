/*
 * Copyright 2025 Arcane
 *
 * Licenced under the Apache License, Version 2.0 (the "Licence");
 * you may not use this file except in compliance with the Licence.
 * You may obtain a copy of the Licence at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the Licence is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the Licence for the specific language governing permissions and
 * limitations under the Licence.
 */
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

    implementation(dependencyNotation = libs.android.splash.screen)

    debugImplementation(dependencyNotation = libs.compose.ui.tooling)
}