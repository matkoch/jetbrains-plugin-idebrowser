package dev.matkoch.ideBrowser

import com.intellij.openapi.actionSystem.DataSink
import com.intellij.openapi.actionSystem.PlatformDataKeys
import com.intellij.openapi.actionSystem.UiDataProvider
import com.intellij.openapi.editor.impl.EditorHeaderComponent
import com.intellij.openapi.ide.CopyPasteManager
import com.intellij.ui.JBColor
import com.intellij.ui.NewUI
import com.intellij.ui.SearchTextField
import com.intellij.util.ui.JBUI
import java.awt.BorderLayout
import java.awt.Color
import java.awt.datatransfer.DataFlavor
import java.awt.event.KeyAdapter
import java.awt.event.KeyEvent
import java.net.URL
import javax.swing.JPanel

class UrlInputComponent(
    initialUrl: String?,
    private val onUrlEntered: (String) -> Unit,
    private val onCancel: () -> Unit
) : EditorHeaderComponent(), UiDataProvider {

    private val searchField = object : SearchTextField(false, null) {
        override fun getBackground(): Color {
            if (NewUI.isEnabled()) {
                return JBColor.namedColor("Editor.SearchField.background", JBColor.background())
            }
            return super.getBackground()
        }
    }.apply {
        textEditor.border = JBUI.Borders.empty()
        border = JBUI.Borders.empty()
    }

    override fun uiDataSnapshot(sink: DataSink) {
        sink.set(PlatformDataKeys.SPEED_SEARCH_TEXT, searchField.text)
    }

    init {
        val isNewUI = NewUI.isEnabled()
        if (isNewUI) {
            background = JBColor.namedColor("Editor.SearchField.background", JBColor.background())
        }

        layout = BorderLayout()

        searchField.isOpaque = !isNewUI
        searchField.textEditor.isOpaque = !isNewUI

        val effectiveUrl = initialUrl?.takeIf { it.isNotBlank() }
            ?: CopyPasteManager.getInstance().getContents<String>(DataFlavor.stringFlavor)?.takeIf { isValidUrl(it) }

        searchField.text = effectiveUrl ?: ""
        searchField.textEditor.selectAll()
        searchField.textEditor.addKeyListener(object : KeyAdapter() {
            override fun keyPressed(e: KeyEvent) {
                if (e.keyCode == KeyEvent.VK_ENTER) {
                    val url = searchField.text
                    if (url.isNotBlank()) {
                        onUrlEntered(normalizeUrl(url))
                    }
                } else if (e.keyCode == KeyEvent.VK_ESCAPE) {
                    onCancel()
                }
            }
        })

        val wrapper = JPanel(BorderLayout())
        wrapper.isOpaque = false
        wrapper.border = JBUI.Borders.empty(JBUI.CurrentTheme.Editor.SearchField.borderInsets())
        wrapper.add(searchField, BorderLayout.CENTER)

        add(wrapper, BorderLayout.CENTER)
    }

    fun requestFocusInField() {
        searchField.requestFocusInWindow()
    }

    private fun normalizeUrl(url: String): String {
        if (url.startsWith("http://") || url.startsWith("https://")) {
            return url
        }
        val prefix = if (url.startsWith("localhost") || url.startsWith("127.0.0.1")) "http://" else "https://"
        return "$prefix$url"
    }

    private fun isValidUrl(url: String): Boolean {
        return try {
            URL(url)
            true
        } catch (_: Exception) {
            false
        }
    }
}
