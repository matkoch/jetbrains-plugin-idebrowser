package dev.matkoch.ideBrowser

import com.intellij.openapi.actionSystem.ActionManager
import com.intellij.openapi.actionSystem.DefaultActionGroup
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

    toolWindow.setTitleActions(listOf(
      actionManager.getAction("dev.matkoch.ideBrowser.HomeAction"),
      actionManager.getAction("dev.matkoch.ideBrowser.BackAction"),
      actionManager.getAction("dev.matkoch.ideBrowser.ForwardAction"),
      actionManager.getAction("dev.matkoch.ideBrowser.ReloadPageAction")
    ))

    toolWindow.setAdditionalGearActions(DefaultActionGroup(listOf(
      actionManager.getAction("dev.matkoch.ideBrowser.OpenUrlAction"),
      actionManager.getAction("dev.matkoch.ideBrowser.OpenDevToolsAction")
    )))
  }
}

val DATA_KEY = Key.create<LoadableHtmlPanel>("LoadableHtmlPanel")
