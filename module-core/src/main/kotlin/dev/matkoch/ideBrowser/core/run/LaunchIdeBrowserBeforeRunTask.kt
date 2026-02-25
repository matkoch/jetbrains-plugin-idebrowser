package dev.matkoch.ideBrowser.core.run

import com.intellij.execution.BeforeRunTask
import com.intellij.openapi.components.PersistentStateComponent
import com.intellij.openapi.util.Key

internal class LaunchIdeBrowserBeforeRunTask : BeforeRunTask<LaunchIdeBrowserBeforeRunTask>(ID),
                                               PersistentStateComponent<LaunchIdeBrowserBeforeRunTaskState> {
  private var state = LaunchIdeBrowserBeforeRunTaskState()

  override fun loadState(state: LaunchIdeBrowserBeforeRunTaskState) {
    state.resetModificationCount()
    this.state = state
  }

  override fun getState(): LaunchIdeBrowserBeforeRunTaskState = state
}
