package dev.matkoch.ideBrowser.core.run

import com.intellij.execution.BeforeRunTaskProvider
import com.intellij.execution.configurations.RunConfiguration
import com.intellij.execution.runners.ExecutionEnvironment
import com.intellij.icons.AllIcons
import com.intellij.openapi.actionSystem.DataContext
import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.project.DumbAware
import com.intellij.openapi.util.Key
import com.intellij.openapi.wm.ToolWindowManager
import com.intellij.ui.dsl.builder.AlignX
import com.intellij.ui.dsl.builder.COLUMNS_MEDIUM
import com.intellij.ui.dsl.builder.columns
import com.intellij.ui.dsl.builder.panel
import dev.matkoch.ideBrowser.core.ui.DATA_KEY
import org.jetbrains.concurrency.Promise
import org.jetbrains.concurrency.resolvedPromise
import javax.swing.Icon
import javax.swing.JTextField

internal val ID: Key<LaunchIdeBrowserBeforeRunTask> = Key.create("LaunchIdeBrowser.Before.Run")

internal class LaunchIdeBrowserBeforeRunTaskProvider : BeforeRunTaskProvider<LaunchIdeBrowserBeforeRunTask>(), DumbAware {

  override fun getId(): Key<LaunchIdeBrowserBeforeRunTask> = ID

  override fun getName(): String = "Launch IDE Browser"

  override fun getIcon(): Icon = AllIcons.Toolwindows.WebToolWindow

  override fun isConfigurable(): Boolean = true

  override fun createTask(runConfiguration: RunConfiguration): LaunchIdeBrowserBeforeRunTask = LaunchIdeBrowserBeforeRunTask()

  override fun configureTask(
    context: DataContext,
    runConfiguration: RunConfiguration,
    task: LaunchIdeBrowserBeforeRunTask
  ): Promise<Boolean> {
    val state = task.state
    val modificationCount = state.modificationCount

    val urlField = JTextField()
    state.url?.let {
      urlField.text = it
    }

    val panel = panel {
      row("URL:") {
        cell(urlField)
          .align(AlignX.FILL)
          .columns(COLUMNS_MEDIUM)
      }
    }

    com.intellij.openapi.ui.DialogBuilder(runConfiguration.project).apply {
      setTitle("Launch IDE Browser")
      setCenterPanel(panel)
      showModal(true)
    }

    state.url = urlField.text

    return resolvedPromise(modificationCount != state.modificationCount)
  }

  override fun executeTask(
    context: DataContext,
    configuration: RunConfiguration,
    environment: ExecutionEnvironment,
    task: LaunchIdeBrowserBeforeRunTask
  ): Boolean {
    val project = configuration.project
    val url = task.state.url ?: return true

    ApplicationManager.getApplication().invokeLater {
      val toolWindow = ToolWindowManager.getInstance(project).getToolWindow("Browser")
      toolWindow?.show {
        val content = toolWindow.contentManager.selectedContent
        val htmlPanel = content?.getUserData(DATA_KEY)
        htmlPanel?.loadURL(url)
      }
    }

    return true
  }
}
