import org.jetbrains.intellij.platform.gradle.IntelliJPlatformType

plugins {
    id("idebrowser.kotlin-conventions")
    id("org.jetbrains.intellij.platform")
    id("idebrowser.dotnet-conventions")
    id("idebrowser.sandbox-config-conventions")
    alias(libs.plugins.changelog)
    alias(libs.plugins.gradleJvmWrapper)
}

version = providers.gradleProperty("pluginVersion").getOrElse("9999.0.0")

allprojects {
    repositories {
        mavenCentral()
    }
}

repositories {
    intellijPlatform {
        defaultRepositories()
        jetbrainsRuntime()
    }
}

sourceSets {
    main {
        resources.srcDir("resources")
    }
}

dependencies {
    intellijPlatform {
        rider(libs.versions.riderSdk) { useInstaller = false }
        jetbrainsRuntime()
        pluginVerifier()
        pluginComposedModule(implementation(project(":module-core")))
        pluginComposedModule(implementation(project(":platform-idea")))
        pluginComposedModule(implementation(project(":platform-rider")))
    }
}

intellijPlatform {
    pluginConfiguration {
        id = pluginSettings.intellijId
        name = pluginSettings.name
        version = project.version.toString()
        description = pluginSettings.description
        vendor {
            name = pluginSettings.vendor
            url = pluginSettings.projectUrl
        }
        changeNotes = providers.gradleProperty("changeNotes").orElse("")
    }

    pluginVerification {
        ides {
            create(IntelliJPlatformType.IntellijIdea, libs.versions.ideaSdk.get()) {
                useInstaller = false
            }
            create(IntelliJPlatformType.Rider, libs.versions.riderSdk.get()) {
                useInstaller = false
            }
        }
    }

    publishing {
        token = providers.environmentVariable("PUBLISH_TOKEN")
        channels = providers.gradleProperty("publishChannel").map { listOf(it) }.orElse(listOf("stable"))
    }
}

val runRider by intellijPlatformTesting.runIde.registering {
    type = IntelliJPlatformType.Rider
    version = libs.versions.riderSdk

    task {
        args = listOf(layout.projectDirectory.file("sample/Sample.slnx").asFile.absolutePath)
    }
}

val runIdea by intellijPlatformTesting.runIde.registering {
    type = IntelliJPlatformType.IntellijIdea
    version = libs.versions.ideaSdk

    task {
        args = listOf(layout.projectDirectory.file("sample").asFile.absolutePath)
    }
}

changelog {
    groups.set(emptyList())
    keepUnreleasedSection.set(false)
}

tasks {
    processResources {
        from("dependencies.json") { into("META-INF") }
    }

    patchPluginXml {
        sinceBuild = "251"
        untilBuild = provider { null }
        changeNotes.set(provider {
            changelog.getAll().values.joinToString("\n") {
                changelog.renderItem(it, org.jetbrains.changelog.Changelog.OutputType.HTML)
            }
        })
    }

    publishPlugin {
        // Allow publishing a pre-built archive instead of building during publish
        providers.gradleProperty("publishArchive").orNull?.let { archivePath ->
            archiveFile.set(layout.projectDirectory.file(archivePath))
        }
    }

    runIde {
        jvmArgs("-Xmx1500m")
    }
}
