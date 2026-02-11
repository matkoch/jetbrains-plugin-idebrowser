plugins {
    id("idebrowser.module-conventions")
}

dependencies {
    compileOnly(project(":module-core"))

    intellijPlatform {
        bundledPlugin("com.intellij.java")
    }
}
