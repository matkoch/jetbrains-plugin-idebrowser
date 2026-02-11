package dev.matkoch.ideBrowser.idea

import com.intellij.execution.RunConfigurationExtension
import com.intellij.execution.configurations.JavaParameters
import com.intellij.execution.configurations.RunConfigurationBase
import com.intellij.execution.configurations.RunnerSettings
import com.intellij.openapi.diagnostic.logger
import dev.matkoch.ideBrowser.core.http.IDE_BROWSER_ENDPOINT_ENV
import dev.matkoch.ideBrowser.core.http.getIdeBrowserEndpoint

private val LOG = logger<IdeBrowserRunConfigurationExtension>()

class IdeBrowserRunConfigurationExtension : RunConfigurationExtension() {

    override fun <T : RunConfigurationBase<*>?> updateJavaParameters(
        configuration: T & Any,
        params: JavaParameters,
        runnerSettings: RunnerSettings?
    ) {
        try {
            params.env[IDE_BROWSER_ENDPOINT_ENV] = getIdeBrowserEndpoint()
        } catch (e: Throwable) {
            LOG.warn("Failed to inject IDE_BROWSER_ENDPOINT environment variable", e)
        }
    }

    override fun isApplicableFor(configuration: RunConfigurationBase<*>): Boolean {
        return true
    }
}
