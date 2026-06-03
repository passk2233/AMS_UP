plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.frontend"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }


    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.frontend"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}


subprojects {
    afterEvaluate {
        val project = this
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            
            // 1. บังคับโปรเจกต์ย่อยทุกตัว (ทั้ง Java และ Kotlin) ให้ใช้ Java 17
            android.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
            
            // 2. ดักจับปลั๊กอินย่อยที่ใช้ Kotlin แล้วเซฟค่า compiler ให้เป็น Java 17 แบบใหม่
            project.plugins.withId("org.jetbrains.kotlin.android") {
                val kotlinExtension = project.extensions.findByType(org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension::class.java)
                kotlinExtension?.compilerOptions?.jvmTarget?.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
            
            // 3. ดักจับเฉพาะงานคอมไพล์ Java ของทุกปลั๊กอินให้ใช้ Java 17 ตรงๆ
            project.tasks.withType(JavaCompile::class.java).configureEach {
                options.compilerArgs.addAll(listOf("-source", "17", "-target", "17"))
            }
        }
    }
}