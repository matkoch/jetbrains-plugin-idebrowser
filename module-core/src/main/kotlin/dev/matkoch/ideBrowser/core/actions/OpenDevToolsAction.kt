package dev.matkoch.ideBrowser.core.actions

import com.intellij.openapi.actionSystem.AnActionEvent

class OpenDevToolsAction : BrowserAction() {
  override fun actionPerformed(e: AnActionEvent) {
    val htmlPanel = getHtmlPanel(e)
    htmlPanel?.browser?.openDevtools()
  }
}
