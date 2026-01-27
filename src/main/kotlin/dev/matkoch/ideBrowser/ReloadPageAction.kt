package dev.matkoch.ideBrowser

import com.intellij.openapi.actionSystem.AnActionEvent

class ReloadPageAction : BrowserAction() {
  override fun actionPerformed(e: AnActionEvent) {
    val htmlPanel = getHtmlPanel(e)
    htmlPanel?.browser?.cefBrowser?.reload()
  }
}
