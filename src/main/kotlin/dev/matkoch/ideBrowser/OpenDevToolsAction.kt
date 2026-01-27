package dev.matkoch.ideBrowser

import com.intellij.openapi.actionSystem.AnActionEvent

class OpenDevToolsAction : BrowserAction() {
  override fun actionPerformed(e: AnActionEvent) {
    val htmlPanel = getHtmlPanel(e)
    htmlPanel?.browser?.openDevtools()
  }
}
