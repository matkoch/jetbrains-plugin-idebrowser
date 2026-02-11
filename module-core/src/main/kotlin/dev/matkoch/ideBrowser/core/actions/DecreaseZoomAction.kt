package dev.matkoch.ideBrowser.core.actions

import com.intellij.openapi.actionSystem.AnActionEvent

class DecreaseZoomAction : BrowserAction(global = true) {
  override fun actionPerformed(e: AnActionEvent) {
    val htmlPanel = getHtmlPanel(e)
    htmlPanel?.decreaseZoom()
  }
}
