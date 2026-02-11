package dev.matkoch.ideBrowser.core.actions

import com.intellij.openapi.actionSystem.AnActionEvent

class HomeAction : BrowserAction() {
  override fun actionPerformed(e: AnActionEvent) {
    getHtmlPanel(e)?.goHome()
  }
}
