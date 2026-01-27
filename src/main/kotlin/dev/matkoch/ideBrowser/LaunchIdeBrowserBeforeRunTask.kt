package dev.matkoch.ideBrowser

import com.intellij.execution.BeforeRunTask
import com.intellij.openapi.util.Key
import org.jdom.Element

class LaunchIdeBrowserBeforeRunTask(providerId: Key<LaunchIdeBrowserBeforeRunTask>) :
  com.intellij.execution.BeforeRunTask<LaunchIdeBrowserBeforeRunTask>(providerId) {
  var url: String? = null

  @Deprecated("Deprecated in Java", ReplaceWith("super.writeExternal(element)"))
  override fun writeExternal(element: Element) {
    super.writeExternal(element)
    url?.let { element.setAttribute("url", it) }
  }

  @Deprecated("Deprecated in Java", ReplaceWith("super.readExternal(element)"))
  override fun readExternal(element: Element) {
    super.readExternal(element)
    url = element.getAttributeValue("url")
  }
}
