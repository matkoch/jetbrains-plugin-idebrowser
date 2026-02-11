package dev.matkoch.ideBrowser.core.actions

import com.intellij.openapi.actionSystem.AnActionEvent

class IncreaseZoomAction : BrowserAction(global = true) {
  override fun actionPerformed(e: AnActionEvent) {
    val htmlPanel = getHtmlPanel(e)
    htmlPanel?.increaseZoom()
  }
}
