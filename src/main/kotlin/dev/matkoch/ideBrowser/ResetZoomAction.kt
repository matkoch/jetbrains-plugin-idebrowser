package dev.matkoch.ideBrowser

import com.intellij.openapi.actionSystem.AnActionEvent

class ResetZoomAction : BrowserAction(global = true) {
  override fun actionPerformed(e: AnActionEvent) {
    val htmlPanel = getHtmlPanel(e)
    htmlPanel?.resetZoom()
  }
}
