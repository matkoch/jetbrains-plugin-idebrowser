package dev.matkoch.ideBrowser.rider

import com.intellij.execution.configurations.GeneralCommandLine
import com.intellij.execution.process.ProcessInfo
import com.intellij.execution.process.ProcessListener
import com.intellij.openapi.actionSystem.DataContext
import com.intellij.openapi.project.Project
import com.jetbrains.rd.util.lifetime.Lifetime
import com.jetbrains.rider.run.PatchCommandLineExtension
import com.jetbrains.rider.run.WorkerRunInfo
import com.jetbrains.rider.runtime.DotNetExecutable
import com.jetbrains.rider.runtime.DotNetRuntime
import dev.matkoch.ideBrowser.core.http.IDE_BROWSER_ENDPOINT_ENV
import dev.matkoch.ideBrowser.core.http.getIdeBrowserEndpoint
import org.jetbrains.concurrency.Promise
import org.jetbrains.concurrency.resolvedPromise

class IdeBrowserPatchCommandLineExtension : PatchCommandLineExtension {

    override fun patchDebugCommandLine(
        lifetime: Lifetime,
        workerRunInfo: WorkerRunInfo,
        processInfo: ProcessInfo?,
        dotNetExecutable: DotNetExecutable?,
        project: Project,
        dataContext: DataContext?
    ): Promise<WorkerRunInfo> {
        workerRunInfo.commandLine.withEnvironment(IDE_BROWSER_ENDPOINT_ENV, getIdeBrowserEndpoint())
        return resolvedPromise(workerRunInfo)
    }

    override fun patchRunCommandLine(
        commandLine: GeneralCommandLine,
        dotNetRuntime: DotNetRuntime,
        dotNetExecutable: DotNetExecutable?,
        project: Project
    ): ProcessListener? {
        commandLine.withEnvironment(IDE_BROWSER_ENDPOINT_ENV, getIdeBrowserEndpoint())
        return null
    }
}
