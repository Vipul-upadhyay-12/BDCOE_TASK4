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
    val configureAndroid: (Project) -> Unit = { proj ->
        proj.extensions.findByName("android")?.let { androidExt ->
            val methods = listOf("compileSdkVersion", "setCompileSdkVersion", "setCompileSdk")
            for (methodName in methods) {
                try {
                    val method = androidExt.javaClass.getMethod(methodName, Int::class.javaPrimitiveType)
                    method.invoke(androidExt, 36)
                    break
                } catch (e: Exception) {
                    // Try next method signature
                }
            }
        }
    }

    if (state.executed) {
        configureAndroid(this)
    } else {
        afterEvaluate {
            configureAndroid(this)
        }
    }
}