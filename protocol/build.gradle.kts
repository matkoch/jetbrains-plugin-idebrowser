import com.jetbrains.rd.generator.gradle.RdGenTask
import java.io.File

plugins {
    kotlin("jvm")
    id("com.jetbrains.rdgen") version libs.versions.rdGen
}

val intellijId = pluginSettings.intellijId
val resharperId = pluginSettings.resharperId

fun generatePluginConstantsFile(outputDir: File) {
    val kotlinModelNamespace = "$intellijId.rider.model"
    val csharpModelNamespace = "$resharperId.Model"

    val dir = outputDir.resolve("model/generated")
    dir.mkdirs()
    dir.resolve("PluginConstants.kt").writeText("""
        package model.generated

        object PluginConstants {
            const val KOTLIN_MODEL_NAMESPACE = "$kotlinModelNamespace"
            const val CSHARP_MODEL_NAMESPACE = "$csharpModelNamespace"
        }
    """.trimIndent())
}

val generatedSrcDir = layout.buildDirectory.dir("generated/src/main/kotlin")

val generatePluginConstants by tasks.registering {
    outputs.dir(generatedSrcDir)
    doLast {
        generatePluginConstantsFile(generatedSrcDir.get().asFile)
    }
}

sourceSets {
    main {
        kotlin.srcDir(generatedSrcDir)
    }
}

tasks.named("compileKotlin") {
    dependsOn(generatePluginConstants)
}

dependencies {
    implementation(libs.rdGen)
    implementation(libs.kotlinStdLib)
    implementation(project(path = ":", configuration = "riderModel"))
}

rdgen {
    verbose = true
    packages = "model"

    generator {
        language = "kotlin"
        transform = "asis"
        root = "com.jetbrains.rider.model.nova.ide.IdeRoot"
        directory = file("${rootProject.projectDir}/platform-rider/src/main/generated/kotlin/${intellijId.replace('.', '/')}/rider").absolutePath
        generatedFileSuffix = ".g"
    }

    generator {
        language = "csharp"
        transform = "reversed"
        root = "com.jetbrains.rider.model.nova.ide.IdeRoot"
        directory = file("${rootProject.projectDir}/platform-resharper/src/$resharperId/Model").absolutePath
        generatedFileSuffix = ".g"
    }
}

tasks.withType<RdGenTask> {
    val classPath = sourceSets["main"].runtimeClasspath
    dependsOn(classPath)
    classpath(classPath)
}
