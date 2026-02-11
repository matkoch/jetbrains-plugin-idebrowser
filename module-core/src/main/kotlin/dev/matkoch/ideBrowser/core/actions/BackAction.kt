package dev.matkoch.ideBrowser.core.actions

import com.intellij.execution.configurations.GeneralCommandLine
import com.intellij.execution.process.CommandLineEnvCustomizer
import com.intellij.openapi.actionSystem.AnActionEvent

class BackAction : BrowserAction() {
  override fun actionPerformed(e: AnActionEvent) {
    getHtmlPanel(e)?.goBack()
  }

  override fun update(e: AnActionEvent) {
    val htmlPanel = getHtmlPanel(e)
    e.presentation.isEnabled = htmlPanel != null && htmlPanel.canGoBack()
  }
}
