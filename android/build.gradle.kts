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

subprojects {
    fun configureNamespace(proj: Project) {
        val isAndroid = proj.plugins.hasPlugin("com.android.application") || 
                        proj.plugins.hasPlugin("com.android.library")
        if (isAndroid) {
            val android = proj.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            if (android != null) {
                if (android.namespace == null) {
                    android.namespace = "com.example.${proj.name.replace("-", "_").replace(".", "_")}"
                }
            }
        }
    }

    if (project.state.executed) {
        configureNamespace(project)
    } else {
        project.afterEvaluate {
            configureNamespace(project)
        }
    }
}

