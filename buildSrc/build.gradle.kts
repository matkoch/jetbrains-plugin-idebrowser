plugins {
    `kotlin-dsl`
}

repositories {
    gradlePluginPortal()
    mavenCentral()
}

dependencies {
    implementation(libs.kotlinGradlePlugin)
    implementation(libs.intellijPlatformPlugin)
    implementation(libs.intellijPlatformModulePlugin)
}
