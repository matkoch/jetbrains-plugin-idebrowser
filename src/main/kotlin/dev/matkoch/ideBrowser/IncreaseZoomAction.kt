package dev.matkoch.ideBrowser

import com.intellij.openapi.actionSystem.AnActionEvent

class IncreaseZoomAction : BrowserAction(global = true) {
  override fun actionPerformed(e: AnActionEvent) {
    val htmlPanel = getHtmlPanel(e)
    htmlPanel?.increaseZoom()
  }
}
