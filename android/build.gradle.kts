allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Explicit namespace overrides for legacy packages that use the deprecated
// package= attribute in their AndroidManifest.xml (not supported in AGP 8+).
val namespaceOverrides = mapOf(
    "image_gallery_saver" to "com.example.imagegallerysaver"
)

subprojects {
    fun configureProject(proj: Project) {
        val isAndroid = proj.plugins.hasPlugin("com.android.application") ||
                        proj.plugins.hasPlugin("com.android.library")
        if (isAndroid) {
            val android = proj.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            if (android != null && android.namespace == null) {
                // Inject namespace for packages that used the deprecated package= attribute
                android.namespace = namespaceOverrides[proj.name]
                    ?: "com.example.${proj.name.replace("-", "_").replace(".", "_")}"
            }
        }
    }

    if (project.state.executed) {
        configureProject(project)
    } else {
        project.afterEvaluate {
            configureProject(project)
        }
    }
}

