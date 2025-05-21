plugins {
    //trick: for the same plugin versions in all sub-modules
    alias(notation = libs.plugins.androidApplication).apply(apply = false)
    alias(notation = libs.plugins.androidLibrary).apply(apply = false)
    alias(notation = libs.plugins.kotlinAndroid).apply(apply = false)
    alias(notation = libs.plugins.kotlinMultiplatform).apply(apply = false)
    alias(notation = libs.plugins.compose.compiler).apply(apply = false)
    alias(notation = libs.plugins.ktlint)
    alias(notation = libs.plugins.detekt)
    alias(notation = libs.plugins.spotless)
}

subprojects {
    apply(plugin = rootProject.libs.plugins.ktlint.get().pluginId)
    ktlint {
        verbose.set(true)
        android.set(true)
        filter {
            exclude("**/generated/**")
        }
    }

    apply(plugin = rootProject.libs.plugins.spotless.get().pluginId)
    configure<com.diffplug.gradle.spotless.SpotlessExtension> {
        kotlin {
            target("**/*.kt")
            targetExclude("**/build/**/*.kt")
            licenseHeaderFile(
                "${project.rootDir}/spotless/copyright.kt",
            )
        }

        format("kts") {
            target("**/*.kts")
            targetExclude("**/build/**/*.kts")
            // Look for the first line that does not have a block comment [assumed to be the license]...
            licenseHeaderFile(
                rootProject.file("spotless/copyright.kts"),
                "(^(?![\\/ ]\\*).*$)",
            )
        }

        format("xml") {
            target("**/*.xml")
            targetExclude("**/build/**/*.xml")
        }

        format("xml") {
            target("**/*.xml")
            targetExclude("**/build/**/*.xml")
            // Look for the first XML tag that isn't a comment [<!--] or the xml declaration [<?xml]...
            licenseHeaderFile(rootProject.file("spotless/copyright.xml"), "(<[^!?])")
        }
    }
}

apply(plugin = rootProject.libs.plugins.detekt.get().pluginId)
detekt {
    parallel = true
}