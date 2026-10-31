plugins {
    id("com.android.library") version "8.5.2"
    id("org.jetbrains.kotlin.android") version "2.1.0"
}

android {
    namespace = "com.troystorygames.emberfield.playback"
    compileSdk = 34

    defaultConfig {
        minSdk = 24
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
    compileOnly("org.godotengine:godot:4.5.1.stable")
}

afterEvaluate {
    tasks.named("assembleRelease").configure {
        doLast {
            val built = layout.buildDirectory.file("outputs/aar/playback_capture-release.aar").get().asFile
            val dest = file("bin/playback_capture.aar")
            dest.parentFile.mkdirs()
            built.copyTo(dest, overwrite = true)
        }
    }
}
