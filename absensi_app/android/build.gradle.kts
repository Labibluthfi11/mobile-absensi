buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    // --- JURUS SUNAT LIBRARY: PAKSA KE VERSI STABIL ---
    configurations.all {
        resolutionStrategy {
            force("androidx.core:core:1.13.1")
            force("androidx.core:core-ktx:1.13.1")
            force("androidx.activity:activity:1.9.3")
            force("androidx.activity:activity-ktx:1.9.3")
        }
    }
}

// Custom build directory logic
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// --- JURUS PAMUNGKAS V3: PAKSA SDK 36 (SAFENODE) ---
subprojects {
    project.plugins.all {
        val plugin = this
        if (plugin::class.java.name.startsWith("com.android.build.gradle.LibraryPlugin")) {
            val android = project.extensions.findByName("android")
            if (android != null) {
                // 1. Fix Namespace untuk Gradle 8+
                try {
                    val getNamespace = android::class.java.getMethod("getNamespace")
                    val setNamespace = android::class.java.getMethod("setNamespace", String::class.java)
                    if (getNamespace.invoke(android) == null) {
                        setNamespace.invoke(android, "com.${project.name.replace("-", ".")}")
                    }
                } catch (e: Exception) { }

                // 2. Fix Error 'lStar' dengan maksa Compile SDK ke 36
                try {
                    val setCompileSdk = android::class.java.getMethod("setCompileSdk", Int::class.javaPrimitiveType)
                    setCompileSdk.invoke(android, 36)
                } catch (e: Exception) {
                    try {
                        val compileSdkVersion = android::class.java.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                        compileSdkVersion.invoke(android, 36)
                    } catch (e2: Exception) { }
                }
            }

            // 3. Hapus 'package' dari Manifest plugin lama
            project.tasks.matching { it.name.contains("Manifest") }.configureEach {
                doFirst {
                    val manifestFile = project.file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val content = manifestFile.readText()
                        if (content.contains("package=")) {
                            val updatedContent = content.replace(Regex("""package="[^"]*""""), "")
                            manifestFile.writeText(updatedContent)
                        }
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}