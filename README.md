# JetBrains IDE Browser Plugin

[![](https://img.shields.io/jetbrains/plugin/v/dev.matkoch.ideBrowser?style=flat-square&logo=jetbrains&label=version)](https://plugins.jetbrains.com/plugin/29952-ide-browser)
[![](https://img.shields.io/jetbrains/plugin/r/rating/dev.matkoch.ideBrowser?style=flat-square)](https://plugins.jetbrains.com/plugin/29952-ide-browser/analytics)
[![](https://img.shields.io/jetbrains/plugin/d/dev.matkoch.ideBrowser?style=flat-square)](https://plugins.jetbrains.com/plugin/29952-ide-browser/reviews)
[![](https://img.shields.io/github/actions/workflow/status/matkoch/rider-idebrowser/build.yml?style=flat-square&logo=github)](https://github.com/matkoch/rider-idebrowser/actions/workflows/build.yml)

## Features

- Minimal browser tool window based on JCEF
- _Before launch task_ for run configurations
- Programmatic interaction via HTTP endpoint
- Toolbar actions for navigation
- Gear actions for opening URL and zoom level

### Programmatic interaction

Java and .NET run configurations get a `IDE_BROWSER_ENDPOINT` environment variable injected that can be used to interact with the plugin. The HTTP requests are constructed as follows:

```
# Open a URL
GET <IDE_BROWSER_ENDPOINT>/open?url=<url>
```

## Usage Examples

> [!TIP]
> Enable `toolwindow.open.tab.in.editor` in your [IntelliJ IDE Registry](https://youtrack.jetbrains.com/articles/SUPPORT-A-1030/How-to-edit-IntelliJ-IDE-Registry) to allow popping out the browser tool window into an editor tab.
