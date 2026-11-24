import java.util.Properties

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.roborazzi)
}

// Release signing reads the upload key from local.properties (never committed): chip.upload.* keys,
// falling back to the shared hotmess.upload.* keys used by the other Love Wins Media apps.
val localProperties = Properties().apply {
    rootProject.file("local.properties").takeIf { it.exists() }?.inputStream()?.use(::load)
}
fun upload(name: String): String? =
    (localProperties.getProperty("chip.upload.$name") ?: localProperties.getProperty("hotmess.upload.$name"))?.takeIf { it.isNotBlank() }

android {
    namespace = "host.lumiere.chip"
    compileSdk = 36

    defaultConfig {
        applicationId = "host.lumiere.chip"
        minSdk = 26
        targetSdk = 36
        // Play needs a higher code for every upload: pass -Pchip.versionCode=N from the build script.
        versionCode = (project.findProperty("chip.versionCode") as String?)?.toInt() ?: 1
        versionName = "1.0.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        // Same rules as the Hot Mess build, so its local.properties can be linked in unchanged:
        // a leading ~ means the home folder, and a missing keyPassword falls back to storePassword
        // (PKCS#12 keystores use one password for both).
        val storeFile = upload("storeFile")?.replaceFirst(Regex("^~(?=/|$)"), System.getProperty("user.home"))
        if (storeFile != null) {
            create("upload") {
                this.storeFile = rootProject.file(storeFile).takeIf { it.exists() } ?: file(storeFile)
                storePassword = upload("storePassword")
                keyAlias = upload("keyAlias")
                keyPassword = upload("keyPassword") ?: upload("storePassword")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.findByName("upload")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures { compose = true }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all { it.systemProperty("robolectric.pixelCopyRenderMode", "hardware") }
        }
    }
}

kotlin { compilerOptions { jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17) } }

dependencies {
    implementation("host.lumiere.chip:chip-core")
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.browser)
    implementation(libs.androidx.exifinterface)
    implementation(libs.kotlinx.coroutines.android)
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.material3)
    implementation(libs.compose.ui.tooling.preview)
    debugImplementation(libs.compose.ui.tooling)
    debugImplementation(libs.compose.ui.test.manifest)

    testImplementation(libs.junit)
    testImplementation(libs.kotlinx.coroutines.test)
    testImplementation(libs.okhttp.mockwebserver)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
    testImplementation(libs.androidx.test.ext.junit)
    testImplementation(platform(libs.compose.bom))
    testImplementation(libs.compose.ui.test.junit4)
    testImplementation(libs.roborazzi)
    testImplementation(libs.roborazzi.compose)
    testImplementation(libs.roborazzi.junit.rule)
}
