import org.gradle.kotlin.dsl.support.serviceOf
import org.jetbrains.intellij.platform.gradle.Constants
import org.jetbrains.intellij.platform.gradle.extensions.IntelliJPlatformExtension
import org.jetbrains.intellij.platform.gradle.tasks.PrepareSandboxTask
import kotlin.io.path.absolute
import kotlin.io.path.isDirectory

/**
 * Convention plugin for .NET/ReSharper backend compilation.
 * Extracts all Rider/.NET specific build logic from the root build.gradle.kts.
 */

val resharperId = pluginSettings.resharperId
val buildConfiguration: String = providers.gradleProperty("buildConfiguration").getOrElse("Debug")

val dotnetSrcDir = file("$projectDir/platform-resharper")

val intellijPlatform = extensions.getByType<IntelliJPlatformExtension>()

val riderSdkPath by lazy {
    val path = intellijPlatform.platformPath.resolve("lib/DotNetSdkForRdPlugins").absolute()
    if (!path.isDirectory()) error("$path does not exist or not a directory")
    path
}

fun findDotNetExecutable(): String {
    // Allow override via gradle.properties
    val override = providers.gradleProperty("dotnetExecutable").orNull
    if (override != null) return override

    val candidates = listOfNotNull(
        System.getenv("DOTNET_ROOT")?.let { "$it/dotnet" },
        "/usr/local/share/dotnet/dotnet",      // macOS official installer
        "/opt/homebrew/bin/dotnet",            // macOS ARM Homebrew
        "/usr/share/dotnet/dotnet",            // Linux default
        "/usr/bin/dotnet",                     // Linux alternative
        System.getProperty("user.home")?.let { "$it/.dotnet/dotnet" },  // User-local install
    )
    return candidates.firstOrNull { file(it).exists() } ?: "dotnet"
}

val dotnetExecutable = findDotNetExecutable().also {
    logger.lifecycle("Using dotnet: $it")
}

// Configuration to expose rider-model.jar to the protocol module
val riderModel: Configuration by configurations.creating {
    isCanBeConsumed = true
    isCanBeResolved = false
}

artifacts {
    add(riderModel.name, provider {
        intellijPlatform.platformPath.resolve("lib/rd/rider-model.jar").also {
            check(it.toFile().isFile) {
                "rider-model.jar is not found at \"$it\"."
            }
        }
    }) {
        builtBy(Constants.Tasks.INITIALIZE_INTELLIJ_PLATFORM_PLUGIN)
    }
}

val riderSdkVersion = versionCatalogs.named("libs").findVersion("riderSdk").get().requiredVersion

tasks {
    val generateDotNetSdkProperties by registering {
        val propsFile = file("$projectDir/build/DotNetSdkPath.Generated.props")
        outputs.file(propsFile)
        doLast {
            propsFile.parentFile.mkdirs()
            propsFile.writeText("""<Project>
  <PropertyGroup>
    <DotNetSdkPath>$riderSdkPath</DotNetSdkPath>
    <SdkVersion>$riderSdkVersion</SdkVersion>
  </PropertyGroup>
</Project>
""")
        }
    }

    val generateNuGetConfig by registering {
        val nugetConfigFile = file("$dotnetSrcDir/nuget.config")
        outputs.file(nugetConfigFile)
        doLast {
            nugetConfigFile.writeText("""<?xml version="1.0" encoding="utf-8"?>
<configuration>
    <packageSources>
        <add key="rider-sdk" value="$riderSdkPath" />
    </packageSources>
</configuration>
""")
        }
    }

    val compileDotNet by registering(Exec::class) {
        dependsOn(":protocol:rdgen", generateDotNetSdkProperties, generateNuGetConfig)
        inputs.property("buildConfiguration", buildConfiguration)
        workingDir(dotnetSrcDir)
        executable(dotnetExecutable)
        args("build", "src/$resharperId/$resharperId.Rider.csproj", "-c", buildConfiguration)
    }

    withType<PrepareSandboxTask> {
        dependsOn(compileDotNet)

        val outputFolder = file("$dotnetSrcDir/src/$resharperId/bin/$resharperId.Rider/$buildConfiguration")
        val pluginFiles = listOf(
            "$outputFolder/${resharperId}.dll",
            "$outputFolder/${resharperId}.pdb"
        )

        from(pluginFiles) {
            into("${rootProject.name}/dotnet")
        }

        doLast {
            for (f in pluginFiles) {
                val file = file(f)
                if (!file.exists()) throw RuntimeException("File \"$file\" does not exist.")
            }
        }
    }
}
