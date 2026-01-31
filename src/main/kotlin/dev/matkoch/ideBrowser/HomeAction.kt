package dev.matkoch.ideBrowser

import com.intellij.openapi.actionSystem.AnActionEvent

class HomeAction : BrowserAction() {
  override fun actionPerformed(e: AnActionEvent) {
    getHtmlPanel(e)?.goHome()
  }
}
