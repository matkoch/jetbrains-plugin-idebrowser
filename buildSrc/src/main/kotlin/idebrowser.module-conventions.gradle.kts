plugins {
    id("idebrowser.kotlin-conventions")
    id("org.jetbrains.intellij.platform.module")
}

repositories {
    mavenCentral()
    intellijPlatform {
        defaultRepositories()
    }
}

dependencies {
    intellijPlatform {
        intellijIdea(versionCatalogs.named("libs").findVersion("ideaSdk").get().requiredVersion) {
            useInstaller = false
        }
        testFramework(org.jetbrains.intellij.platform.gradle.TestFrameworkType.Bundled)
    }
    testImplementation(versionCatalogs.named("libs").findLibrary("junit").get())
}
