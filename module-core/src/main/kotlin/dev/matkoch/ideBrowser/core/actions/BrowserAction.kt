package dev.matkoch.ideBrowser.core.actions

import com.intellij.openapi.actionSystem.ActionUpdateThread
import com.intellij.openapi.actionSystem.AnAction
import com.intellij.openapi.actionSystem.AnActionEvent
import com.intellij.openapi.actionSystem.PlatformDataKeys
import com.intellij.openapi.wm.ToolWindowManager
import dev.matkoch.ideBrowser.core.ui.DATA_KEY
import dev.matkoch.ideBrowser.core.ui.LoadableHtmlPanel

abstract class BrowserAction(private val global: Boolean = false) : AnAction() {
  override fun update(e: AnActionEvent) {
    e.presentation.isEnabledAndVisible = getHtmlPanel(e) != null
  }

  override fun getActionUpdateThread(): ActionUpdateThread {
    return ActionUpdateThread.EDT
  }

  protected fun getHtmlPanel(e: AnActionEvent): LoadableHtmlPanel? {
    val project = e.project ?: return null
    val toolWindow = if (global) {
      ToolWindowManager.getInstance(project).getToolWindow("Browser")
    } else {
      e.getData(PlatformDataKeys.TOOL_WINDOW)
    }
    val content = toolWindow?.contentManager?.selectedContent
    return content?.getUserData(DATA_KEY)
  }
}
