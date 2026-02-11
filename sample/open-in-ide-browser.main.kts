import java.net.URI
import java.net.URLEncoder
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse

println("Opening URL in IDE Browser...")

val endpoint = System.getenv("IDE_BROWSER_ENDPOINT")
if (endpoint != null) {
    println("IDE_BROWSER_ENDPOINT = $endpoint")

    try {
        val httpClient = HttpClient.newHttpClient()
        val url = args.firstOrNull() ?: "https://google.com"
        val encodedUrl = URLEncoder.encode(url, Charsets.UTF_8)
        val request = HttpRequest.newBuilder()
            .uri(URI.create("$endpoint/open?url=$encodedUrl"))
            .GET()
            .build()

        val response = httpClient.send(request, HttpResponse.BodyHandlers.ofString())
        println("Opened $url in IDE browser: ${response.statusCode()}")
    } catch (e: Exception) {
        System.err.println("Failed to call IDE browser endpoint: ${e.message}")
    }
} else {
    println("IDE_BROWSER_ENDPOINT not set - not running from IDE?")
}
