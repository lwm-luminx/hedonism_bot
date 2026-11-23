// The upload core is its own build so it can be built and tested with only Maven Central
// (no Android SDK or Google Maven). The app includes it with includeBuild("core").
pluginManagement {
    repositories {
        gradlePluginPortal()
        mavenCentral()
    }
}

dependencyResolutionManagement {
    repositories { mavenCentral() }
    versionCatalogs {
        create("libs") { from(files("../gradle/libs.versions.toml")) }
    }
}

rootProject.name = "chip-core"
