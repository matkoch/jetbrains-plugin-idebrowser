package dev.matkoch.ideBrowser

import com.intellij.openapi.actionSystem.AnActionEvent

class DecreaseZoomAction : BrowserAction(global = true) {
  override fun actionPerformed(e: AnActionEvent) {
    val htmlPanel = getHtmlPanel(e)
    htmlPanel?.decreaseZoom()
  }
}
