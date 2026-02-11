import org.jetbrains.intellij.platform.gradle.IntelliJPlatformType
import org.jetbrains.intellij.platform.gradle.extensions.IntelliJPlatformTestingExtension
import java.io.File

fun copyLocalIdeSettings(ideType: IntelliJPlatformType, sandboxConfigDir: File) {
    if (sandboxConfigDir.exists()) return

    val prefix = ideType.name.lowercase()

    // Please report if your environment is not covered
    val userHome = System.getProperty("user.home")
    val configDirs = listOf(
        "$userHome/Library/Application Support/JetBrains",
        "${System.getenv("APPDATA") ?: ""}/JetBrains",
        "${System.getenv("XDG_CONFIG_HOME") ?: "$userHome/.config"}/JetBrains"
    )

    val sourceConfig = configDirs
        .mapNotNull { dir -> File(dir).takeIf { it.isDirectory } }
        .flatMap { dir -> dir.listFiles()?.toList() ?: emptyList() }
        .filter { it.isDirectory && it.name.lowercase().startsWith(prefix) }
        .maxByOrNull { it.lastModified() } ?: return

    sandboxConfigDir.mkdirs()
    sourceConfig.listFiles()?.filter { it.name != "plugins" }?.forEach { file ->
        file.copyRecursively(File(sandboxConfigDir, file.name), overwrite = false)
    }
}

afterEvaluate {
    extensions.findByType<IntelliJPlatformTestingExtension>()?.runIde?.all {
        val ideType = type.orNull ?: return@all

        prepareSandboxTask {
            val configDir = sandboxConfigDirectory
            doFirst {
                copyLocalIdeSettings(ideType, configDir.get().asFile)
            }
        }
    }
}
