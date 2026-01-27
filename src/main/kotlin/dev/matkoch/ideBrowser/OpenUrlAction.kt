package dev.matkoch.ideBrowser

import com.intellij.openapi.actionSystem.AnActionEvent
import com.intellij.openapi.ide.CopyPasteManager
import com.intellij.openapi.ui.Messages
import java.awt.datatransfer.DataFlavor
import java.net.URL

class OpenUrlAction : BrowserAction(global = true) {
  override fun actionPerformed(e: AnActionEvent) {
    val project = e.project ?: return
    val htmlPanel = getHtmlPanel(e) ?: return

    val clipboardText = CopyPasteManager.getInstance().getContents<String>(DataFlavor.stringFlavor)
    val defaultValue = if (clipboardText != null && isValidUrl(clipboardText)) clipboardText else "http://"

    val result = Messages.showInputDialog(
      project,
      "Enter URL:",
      "Open URL",
      Messages.getQuestionIcon(),
      defaultValue,
      null
    )
    if (!result.isNullOrBlank()) {
      htmlPanel.loadURL(result)
    }
  }

  private fun isValidUrl(url: String): Boolean {
    return try {
      URL(url)
      true
    } catch (e: Exception) {
      false
    }
  }
}
