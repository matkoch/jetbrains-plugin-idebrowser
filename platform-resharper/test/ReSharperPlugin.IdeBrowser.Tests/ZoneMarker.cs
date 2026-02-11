using JetBrains.Application.BuildScript.Application.Zones;

namespace ReSharperPlugin.IdeBrowser.Tests;

[ZoneMarker]
public class ZoneMarker : IRequire<IdeBrowserTestEnvironmentZone>;
