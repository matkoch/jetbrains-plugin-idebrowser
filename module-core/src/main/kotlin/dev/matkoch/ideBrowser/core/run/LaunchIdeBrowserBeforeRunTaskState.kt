package dev.matkoch.ideBrowser.core.run

import com.intellij.openapi.components.BaseState
import com.intellij.util.xmlb.annotations.Attribute

internal class LaunchIdeBrowserBeforeRunTaskState : BaseState() {
  @get:Attribute()
  var url: String? by string()
}
