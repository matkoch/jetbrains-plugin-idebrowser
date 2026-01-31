package dev.matkoch.ideBrowser

import com.intellij.openapi.actionSystem.AnActionEvent

class ForwardAction : BrowserAction() {
  override fun actionPerformed(e: AnActionEvent) {
    getHtmlPanel(e)?.goForward()
  }

  override fun update(e: AnActionEvent) {
    val htmlPanel = getHtmlPanel(e)
    e.presentation.isEnabled = htmlPanel != null && htmlPanel.canGoForward()
  }
}
