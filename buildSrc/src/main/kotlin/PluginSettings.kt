import org.gradle.api.Project
import groovy.json.JsonSlurper

/**
 * Plugin settings loaded from plugin.json
 */
object PluginSettings {
    lateinit var intellijId: String
        private set
    lateinit var resharperId: String
        private set
    lateinit var name: String
        private set
    lateinit var description: String
        private set
    lateinit var vendor: String
        private set
    lateinit var copyright: String
        private set
    lateinit var projectUrl: String
        private set
    lateinit var licenseUrl: String
        private set
    lateinit var iconUrl: String
        private set

    private var initialized = false

    fun initialize(project: Project) {
        if (initialized) return

        @Suppress("UNCHECKED_CAST")
        val json = JsonSlurper().parseText(
            project.rootProject.file("plugin.json").readText()
        ) as Map<String, String>

        intellijId = json["intellijId"] ?: error("intellijId not found in plugin.json")
        resharperId = json["resharperId"] ?: error("resharperId not found in plugin.json")
        name = json["name"] ?: error("name not found in plugin.json")
        description = json["description"] ?: error("description not found in plugin.json")
        vendor = json["vendor"] ?: error("vendor not found in plugin.json")
        copyright = json["copyright"] ?: error("copyright not found in plugin.json")
        projectUrl = json["projectUrl"] ?: error("projectUrl not found in plugin.json")
        licenseUrl = json["licenseUrl"] ?: error("licenseUrl not found in plugin.json")
        iconUrl = json["iconUrl"] ?: error("iconUrl not found in plugin.json")

        initialized = true
    }
}

/**
 * Extension property to access plugin settings from any project
 */
val Project.pluginSettings: PluginSettings
    get() {
        PluginSettings.initialize(this)
        return PluginSettings
    }
