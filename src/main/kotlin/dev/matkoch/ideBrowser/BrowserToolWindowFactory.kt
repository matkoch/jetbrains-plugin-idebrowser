package dev.matkoch.ideBrowser

import com.intellij.openapi.actionSystem.ActionManager
import com.intellij.openapi.project.Project
import com.intellij.openapi.util.Key
import com.intellij.openapi.wm.ToolWindow
import com.intellij.openapi.wm.ToolWindowFactory
import com.intellij.ui.content.ContentFactory

class BrowserToolWindowFactory : ToolWindowFactory {

  override fun createToolWindowContent(project: Project, toolWindow: ToolWindow) {
    val contentFactory = ContentFactory.getInstance()
    val htmlPanel = LoadableHtmlPanel(null, null)
    val content = contentFactory.createContent(htmlPanel.component, null, false)
    content.putUserData(DATA_KEY, htmlPanel)
    toolWindow.contentManager.addContent(content)

    val actionManager = ActionManager.getInstance()
    val openUrlAction = actionManager.getAction("dev.matkoch.ideBrowser.OpenUrlAction")
    val reloadAction = actionManager.getAction("dev.matkoch.ideBrowser.ReloadPageAction")
    val devToolsAction = actionManager.getAction("dev.matkoch.ideBrowser.OpenDevToolsAction")
    toolWindow.setTitleActions(listOf(openUrlAction, reloadAction, devToolsAction))
  }
}

val DATA_KEY = Key.create<LoadableHtmlPanel>("LoadableHtmlPanel")
