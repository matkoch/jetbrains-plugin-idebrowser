#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Builds and publishes the ReSharper and IntelliJ plugins.

.DESCRIPTION
    This script builds both plugins using build-plugin.ps1 and then publishes them
    to JetBrains Marketplace (IntelliJ/Rider) and NuGet feed (ReSharper).

    The version is determined automatically using minver-cli from the git tag.

    Requires PUBLISH_TOKEN environment variable to be set for authentication.

.PARAMETER Channel
    JetBrains Marketplace channel for the IntelliJ plugin. Defaults to "stable".

.PARAMETER NuGetSource
    NuGet source URL for the ReSharper plugin. Defaults to JetBrains Plugins feed.

.PARAMETER Configuration
    Build configuration: Debug or Release. Defaults to Release.

.PARAMETER SkipReSharper
    Skip publishing the ReSharper plugin.

.PARAMETER SkipIntelliJ
    Skip publishing the IntelliJ/Rider plugin.

.PARAMETER SkipBuild
    Skip the build step (assumes artifacts already exist in artifacts/).

.EXAMPLE
    ./scripts/publish-plugin.ps1
    # Builds and publishes both plugins to default channels

.EXAMPLE
    ./scripts/publish-plugin.ps1 -Channel beta
    # Publishes IntelliJ plugin to the beta channel

.EXAMPLE
    ./scripts/publish-plugin.ps1 -SkipReSharper
    # Only publishes the IntelliJ/Rider plugin

.EXAMPLE
    ./scripts/publish-plugin.ps1 -NuGetSource https://api.nuget.org/v3/index.json
    # Publishes ReSharper plugin to NuGet.org instead of JetBrains feed
#>

param(
    [string]$Channel = "stable",

    [string]$NuGetSource = "https://plugins.jetbrains.com",

    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",

    [switch]$SkipReSharper,

    [switch]$SkipIntelliJ,

    [switch]$SkipBuild
)

. "$PSScriptRoot/settings.ps1"

$ArtifactsDir = "$RepoRoot/artifacts"

# Check for PUBLISH_TOKEN
if (-not $env:PUBLISH_TOKEN) {
    throw "PUBLISH_TOKEN environment variable is not set."
}

# Get version from git tag using minver
$Version = & dotnet dnx --yes minver-cli
if ($LASTEXITCODE -ne 0) {
    throw "minver-cli failed with exit code $LASTEXITCODE"
}

# ------------------------------------------------------------------------------
# Header
# ------------------------------------------------------------------------------

Write-Header "Publish Plugin" @{
    Version       = $Version
    Configuration = $Configuration
    Channel       = $Channel
    NuGetSource   = $NuGetSource
}

# ------------------------------------------------------------------------------
# Build plugins
# ------------------------------------------------------------------------------

if (-not $SkipBuild) {
    Write-Step "Building plugins"

    $buildArgs = @(
        "-Version", $Version,
        "-Configuration", $Configuration
    )
    if ($SkipReSharper) { $buildArgs += "-SkipReSharper" }
    if ($SkipIntelliJ) { $buildArgs += "-SkipIntelliJ" }

    & "$PSScriptRoot/build-plugin.ps1" @buildArgs
    if ($LASTEXITCODE -ne 0) {
        throw "build-plugin.ps1 failed with exit code $LASTEXITCODE"
    }
    Write-Host ""
}

# ------------------------------------------------------------------------------
# Publish plugins
# ------------------------------------------------------------------------------

$failures = @()

if (-not $SkipIntelliJ) {
    Write-Step "Publishing IntelliJ/Rider plugin to JetBrains Marketplace (channel: $Channel)"

    $ArchivePath = "$ArtifactsDir/$IntelliJId-$Version.zip"
    if (-not (Test-Path $ArchivePath)) {
        Write-Error "Archive not found: $ArchivePath"
        $failures += "IntelliJ"
    } else {
        Push-Location $RepoRoot
        try {
            & $Gradlew publishPlugin `
                "-PpluginVersion=$Version" `
                "-PpublishArchive=$ArchivePath" `
                "-PpublishChannel=$Channel"

            if ($LASTEXITCODE -ne 0) {
                Write-Error "publishPlugin failed with exit code $LASTEXITCODE"
                $failures += "IntelliJ"
            } else {
                Write-Success "IntelliJ/Rider plugin published"
            }
        } finally {
            Pop-Location
        }
    }
    Write-Host ""
}

if (-not $SkipReSharper) {
    Write-Step "Publishing ReSharper plugin to $NuGetSource"

    $PackagePath = "$ArtifactsDir/$ReSharperId.$Version.nupkg"
    if (-not (Test-Path $PackagePath)) {
        Write-Error "NuGet package not found: $PackagePath"
        $failures += "ReSharper"
    } else {
        & dotnet nuget push $PackagePath `
            --source $NuGetSource `
            --api-key $env:PUBLISH_TOKEN

        if ($LASTEXITCODE -ne 0) {
            Write-Error "dotnet nuget push failed with exit code $LASTEXITCODE"
            $failures += "ReSharper"
        } else {
            Write-Success "ReSharper plugin published"
        }
    }
    Write-Host ""
}

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------

if ($failures.Count -gt 0) {
    Write-Host "Publishing completed with failures: $($failures -join ', ')" -ForegroundColor Red
    exit 1
} else {
    Write-Success "Publishing completed successfully!"
}
