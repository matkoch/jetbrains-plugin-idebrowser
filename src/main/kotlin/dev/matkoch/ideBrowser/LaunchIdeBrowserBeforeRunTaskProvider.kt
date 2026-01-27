package dev.matkoch.ideBrowser

import com.intellij.execution.BeforeRunTaskProvider
import com.intellij.execution.configurations.RunConfiguration
import com.intellij.execution.runners.ExecutionEnvironment
import com.intellij.icons.AllIcons
import com.intellij.openapi.actionSystem.DataContext
import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.ui.Messages
import com.intellij.openapi.util.Key
import com.intellij.openapi.wm.ToolWindowManager
import javax.swing.Icon

class LaunchIdeBrowserBeforeRunTaskProvider : com.intellij.execution.BeforeRunTaskProvider<LaunchIdeBrowserBeforeRunTask>() {

  override fun getId(): Key<LaunchIdeBrowserBeforeRunTask> = ID

  override fun getName(): String = "Launch IDE Browser"

  override fun getIcon(): Icon = AllIcons.Toolwindows.WebToolWindow

  override fun createTask(runConfiguration: RunConfiguration): LaunchIdeBrowserBeforeRunTask {
    return LaunchIdeBrowserBeforeRunTask(ID)
  }

  override fun isConfigurable(): Boolean = true

  @Deprecated("Deprecated in Java")
  override fun configureTask(
    runConfiguration: RunConfiguration,
    task: LaunchIdeBrowserBeforeRunTask
  ): Boolean {
    val newUrl = Messages.showInputDialog(
      runConfiguration.project,
      "Enter URL:",
      "Launch IDE Browser",
      null,
      task.url,
      null
    )
    if (newUrl != null) {
      task.url = newUrl
      return true
    }
    return false
  }

  override fun executeTask(
    context: DataContext,
    configuration: RunConfiguration,
    environment: ExecutionEnvironment,
    task: LaunchIdeBrowserBeforeRunTask
  ): Boolean {
    val project = configuration.project
    val url = task.url ?: return true

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

val ID: Key<LaunchIdeBrowserBeforeRunTask> = Key.create("LaunchIdeBrowserBeforeRunTaskProvider")
