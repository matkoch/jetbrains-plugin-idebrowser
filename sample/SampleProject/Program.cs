using System.Net;

Console.WriteLine("Opening URL in IDE Browser...");

var endpoint = Environment.GetEnvironmentVariable("IDE_BROWSER_ENDPOINT");
if (endpoint != null)
{
    Console.WriteLine($"IDE_BROWSER_ENDPOINT = {endpoint}");

    try
    {
        using var httpClient = new HttpClient();
        var url = args.FirstOrDefault() ?? "https://google.com";
        var encodedUrl = WebUtility.UrlEncode(url);
        var requestUri = $"{endpoint}/open?url={encodedUrl}";

        var response = await httpClient.GetAsync(requestUri);
        Console.WriteLine($"Opened {url} in IDE browser: {(int)response.StatusCode}");
    }
    catch (Exception e)
    {
        Console.Error.WriteLine($"Failed to call IDE browser endpoint: {e.Message}");
    }
}
else
{
    Console.WriteLine("IDE_BROWSER_ENDPOINT not set - not running from IDE?");
}
