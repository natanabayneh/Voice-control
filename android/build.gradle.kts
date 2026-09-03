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

// The bluetooth_classic plugin pins `compileSdkVersion 31`, which forces
// everyone building this project to install a years-old platform SDK.
// Compile every plugin against the same SDK the app uses instead.
subprojects {
    if (project.name == "app") return@subprojects
    afterEvaluate {
        val androidExtension = project.extensions.findByName("android")
            ?: return@afterEvaluate
        runCatching {
            androidExtension.javaClass
                .getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                .invoke(androidExtension, 35)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
