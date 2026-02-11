package dev.matkoch.ideBrowser.core.http

import com.intellij.openapi.application.invokeLater
import com.intellij.openapi.project.ProjectManager
import com.intellij.openapi.wm.ToolWindowManager
import dev.matkoch.ideBrowser.core.ui.DATA_KEY
import io.netty.channel.ChannelHandlerContext
import io.netty.handler.codec.http.FullHttpRequest
import io.netty.handler.codec.http.HttpResponseStatus
import io.netty.handler.codec.http.QueryStringDecoder
import org.jetbrains.ide.BuiltInServerManager
import org.jetbrains.ide.HttpRequestHandler
import org.jetbrains.ide.RestService

const val IDE_BROWSER_HANDLER_NAME = "ide-browser"
const val IDE_BROWSER_ENDPOINT_ENV = "IDE_BROWSER_ENDPOINT"
private const val PREFIX = "/api/$IDE_BROWSER_HANDLER_NAME"

fun getIdeBrowserEndpoint(): String {
    val port = BuiltInServerManager.getInstance().port
    return "http://localhost:$port/api/$IDE_BROWSER_HANDLER_NAME"
}

class IdeBrowserHttpHandler : HttpRequestHandler() {

  override fun isSupported(request: FullHttpRequest): Boolean {
    return super.isSupported(request) && request.uri().startsWith(PREFIX)
  }

  override fun process(
    urlDecoder: QueryStringDecoder,
    request: FullHttpRequest,
    context: ChannelHandlerContext
  ): Boolean {
    val path = urlDecoder.path()

    return when {
      path == "$PREFIX/open" || path == "$PREFIX/open/" -> {
        handleOpenUrl(urlDecoder, request, context)
      }

      else -> {
        RestService.sendStatus(HttpResponseStatus.NOT_FOUND, false, context.channel())
        true
      }
    }
  }

  private fun handleOpenUrl(
    urlDecoder: QueryStringDecoder,
    request: FullHttpRequest,
    context: ChannelHandlerContext
  ): Boolean {
    val url = urlDecoder.parameters()["url"]?.firstOrNull()

    if (url.isNullOrBlank()) {
      RestService.sendStatus(HttpResponseStatus.BAD_REQUEST, false, context.channel())
      return true
    }

    val project = ProjectManager.getInstance().openProjects.firstOrNull()
    if (project == null) {
      RestService.sendStatus(HttpResponseStatus.SERVICE_UNAVAILABLE, false, context.channel())
      return true
    }

    invokeLater {
      val toolWindowManager = ToolWindowManager.getInstance(project)
      val toolWindow = toolWindowManager.getToolWindow("Browser")

      toolWindow?.show {
        val content = toolWindow.contentManager.selectedContent
        val htmlPanel = content?.getUserData(DATA_KEY)
        htmlPanel?.loadURL(url)
      }
    }

    RestService.sendOk(request, context)
    return true
  }
}
