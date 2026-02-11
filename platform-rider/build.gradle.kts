import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

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
        rider(libs.versions.riderSdk) { useInstaller = false }
        testFramework(org.jetbrains.intellij.platform.gradle.TestFrameworkType.Bundled)
    }
    compileOnly(project(":module-core"))
    testImplementation(libs.junit)
}

sourceSets {
    main {
        kotlin.srcDir("src/main/generated/kotlin")
    }
}

tasks {
    withType<KotlinCompile> {
        dependsOn(":protocol:rdgen")
    }
}
