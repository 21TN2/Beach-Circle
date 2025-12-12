allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 🔥 THIS IS THE MAGIC FIX 🔥
// It tells Gradle: "Put the build files in the folder ABOVE 'android', not inside it."
val newBuildDir: Directory = rootProject.layout.projectDirectory.dir("../build")
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