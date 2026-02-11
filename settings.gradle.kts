@Suppress("UNCHECKED_CAST")
val pluginConfig = groovy.json.JsonSlurper().parseText(file("plugin.json").readText()) as Map<String, String>

rootProject.name = pluginConfig["intellijId"]!!

pluginManagement {
    repositories {
        gradlePluginPortal()
        mavenCentral()
    }
    resolutionStrategy {
        eachPlugin {
            if (requested.id.id == "com.jetbrains.rdgen") {
                useModule("com.jetbrains.rd:rd-gen:${requested.version}")
            }
        }
    }
}

include(":module-core")
include(":platform-idea")
include(":platform-rider")
include(":protocol")
