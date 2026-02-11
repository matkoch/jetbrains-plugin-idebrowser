#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Builds and packages the ReSharper and IntelliJ plugins.

.DESCRIPTION
    This script builds both the IntelliJ/Rider plugin (via Gradle) and the
    ReSharper plugin (via dotnet pack).

.PARAMETER Version
    The version to use for the plugin. Required.

.PARAMETER Configuration
    Build configuration: Debug or Release. Defaults to Release.

.PARAMETER SkipReSharper
    Skip building the ReSharper plugin.

.PARAMETER SkipIntelliJ
    Skip building the IntelliJ/Rider plugin.

.PARAMETER Unpack
    Extract the built artifacts for testing/inspection.

.EXAMPLE
    ./scripts/build-plugin.ps1 -Version 1.0.0
    # Builds both plugins in Release mode

.EXAMPLE
    ./scripts/build-plugin.ps1 -Version 1.2.3 -Configuration Debug
    # Builds both plugins in Debug mode

.EXAMPLE
    ./scripts/build-plugin.ps1 -Version 1.0.0 -SkipReSharper
    # Builds only the IntelliJ/Rider plugin
#>

param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Version,

    [Parameter(Position = 1)]
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",

    [switch]$SkipReSharper,

    [switch]$SkipIntelliJ,

    [switch]$Unpack
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\settings.ps1"

$ArtifactsDir = "$RepoRoot\artifacts"

# ------------------------------------------------------------------------------
# Header
# ------------------------------------------------------------------------------

Write-Header "Build Plugin" @{
    Version       = $Version
    Configuration = $Configuration
}

# ------------------------------------------------------------------------------
# Clean artifacts directory
# ------------------------------------------------------------------------------

if (Test-Path $ArtifactsDir) {
    Remove-Item -Path $ArtifactsDir -Recurse -Force
}
New-Item -ItemType Directory -Path $ArtifactsDir | Out-Null

# ------------------------------------------------------------------------------
# Build plugins
# ------------------------------------------------------------------------------

Push-Location $RepoRoot
try {
    if (-not $SkipIntelliJ) {
        Write-Step "Building IntelliJ plugin"

        Invoke-Exe $Gradlew buildPlugin "-PpluginVersion=$Version" "-PbuildConfiguration=$Configuration"

        Copy-Item -Path "$RepoRoot\build\distributions\$IntelliJId-$Version.zip" -Destination $ArtifactsDir

        Write-Success "IntelliJ plugin built"
    }

    if (-not $SkipReSharper) {
        Write-Step "Building ReSharper plugin"

        $ProjectPath = "$RepoRoot\platform-resharper\src\$ReSharperId\$ReSharperId.ReSharper.csproj"

        $PackArgs = @(
            "pack", $ProjectPath,
            "-c", $Configuration,
            "-o", $ArtifactsDir,
            "/p:Version=$Version",
            "/p:Title=$($PluginConfig.name)",
            "/p:Description=$($PluginConfig.description)",
            "/p:Authors=$($PluginConfig.vendor)",
            "/p:Copyright=$($PluginConfig.copyright)",
            "/p:PackageProjectUrl=$($PluginConfig.projectUrl)",
            "/p:PackageLicenseUrl=$($PluginConfig.licenseUrl)",
            "/p:PackageIconUrl=$($PluginConfig.iconUrl)"
        )

        Invoke-Exe dotnet @PackArgs
        Write-Success "ReSharper plugin built"
    }

    if ($Unpack) {
        Write-Step "Unpacking artifacts"

        # Unpack IntelliJ plugin
        if (-not $SkipIntelliJ) {
            $Zip = Get-ChildItem "$ArtifactsDir\$IntelliJId-*.zip" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($Zip) {
                $ExtractDir = "$ArtifactsDir\$($Zip.BaseName)"
                Expand-Archive -Path $Zip -DestinationPath $ExtractDir -Force

                $Jar = Get-ChildItem "$ExtractDir\*\lib\$IntelliJId-*.jar" -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -notmatch "searchableOptions" } |
                    Select-Object -First 1
                if ($Jar) {
                    $JarExtractDir = "$ArtifactsDir\$($Zip.BaseName)-jar"
                    Expand-Archive -Path $Jar -DestinationPath $JarExtractDir -Force

                    $PluginXml = Get-ChildItem "$JarExtractDir\META-INF\plugin.xml" -ErrorAction SilentlyContinue
                    if ($PluginXml) {
                        Copy-Item -Path $PluginXml -Destination $ArtifactsDir
                    }
                }
            }
        }

        # Unpack ReSharper plugin
        if (-not $SkipReSharper) {
            $Nupkg = Get-ChildItem "$ArtifactsDir\$ReSharperId.*.nupkg" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($Nupkg) {
                $ExtractDir = "$ArtifactsDir\$($Nupkg.BaseName)"
                Expand-Archive -Path $Nupkg -DestinationPath $ExtractDir -Force

                $Nuspec = Get-ChildItem "$ExtractDir\*.nuspec" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($Nuspec) {
                    Copy-Item -Path $Nuspec -Destination $ArtifactsDir
                }
            }
        }
    }

} finally {
    Pop-Location
}

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------

Write-Host ""
Write-Success "Build complete!"
Write-Info "Artifacts: $ArtifactsDir"
Get-ChildItem $ArtifactsDir -File | ForEach-Object { Write-Info "  $($_.Name)" }
