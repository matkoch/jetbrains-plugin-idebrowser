#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Updates dependency versions in libs.versions.toml from Maven metadata.

.DESCRIPTION
    This script reads Maven metadata URLs from comments in libs.versions.toml,
    fetches the latest stable versions, and updates the file.

    Each version entry should have a comment on the line above with the metadata URL:
        # https://repo.maven.apache.org/maven2/org/jetbrains/kotlin/kotlin-stdlib/maven-metadata.xml
        kotlin = "2.3.10"

    For JetBrains SDK versions (rdGen, ideaSdk, riderSdk), you can constrain updates
    to a specific major version prefix to keep them aligned.

.PARAMETER SdkMajorVersion
    Constrains rdGen, ideaSdk, and riderSdk to this major version prefix (e.g., "2025").
    If not specified, uses the latest available version.

.PARAMETER DryRun
    Shows what would be updated without making changes.

.EXAMPLE
    ./scripts/update-catalog.ps1
    # Updates all versions to latest stable

.EXAMPLE
    ./scripts/update-catalog.ps1 -SdkMajorVersion 2025
    # Updates all versions, but keeps SDK versions within 2025.x.x

.EXAMPLE
    ./scripts/update-catalog.ps1 -DryRun
    # Shows what would be updated without making changes
#>

param(
    [Parameter(Position = 0)]
    [string]$SdkMajorVersion,

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Version keys that should be constrained by SdkMajorVersion
$sdkVersionKeys = @("rdGen", "ideaSdk", "riderSdk")

$tomlPath = Join-Path $PSScriptRoot "../gradle/libs.versions.toml"
$tomlContent = Get-Content $tomlPath -Raw

function Get-VersionEntries {
    param([string]$Content)

    # Match: # <url>\n<key> = "<version>"
    $pattern = '(?m)^#\s*(https?://\S+)\s*\n(\w+)\s*=\s*"([^"]+)"'
    $matches = [regex]::Matches($Content, $pattern)

    # Use ordered dictionary to preserve file order
    $entries = [ordered]@{}
    foreach ($match in $matches) {
        $url = $match.Groups[1].Value
        $key = $match.Groups[2].Value
        $version = $match.Groups[3].Value
        $entries[$key] = @{
            Url = $url
            Version = $version
        }
    }
    return $entries
}

function Get-LatestVersion {
    param(
        [string]$MetadataUrl,
        [string]$MajorVersionPrefix
    )

    try {
        $response = Invoke-WebRequest -Uri $MetadataUrl -UseBasicParsing -TimeoutSec 30
        $xml = [xml]$response.Content

        $versions = $xml.metadata.versioning.versions.version | ForEach-Object { $_.ToString() }

        # Filter out pre-release versions (beta, rc, alpha, snapshot, etc.)
        $stableVersions = $versions | Where-Object {
            $_ -notmatch '(?i)(alpha|beta|rc|snapshot|dev|eap|canary|preview|m\d+$)'
        }

        # If major version prefix specified, filter to that
        if ($MajorVersionPrefix) {
            $stableVersions = $stableVersions | Where-Object { $_.StartsWith($MajorVersionPrefix) }
        }

        if (-not $stableVersions) {
            return $null
        }

        # Sort versions and get the latest
        $sorted = $stableVersions | Sort-Object {
            $parts = $_ -split '[.\-]'
            ($parts | ForEach-Object { $_.PadLeft(10, '0') }) -join '.'
        }

        return $sorted | Select-Object -Last 1
    }
    catch {
        Write-Warning "Failed to fetch $MetadataUrl : $_"
        return $null
    }
}

function Update-VersionInToml {
    param(
        [string]$Content,
        [string]$VersionKey,
        [string]$NewVersion
    )

    $pattern = "(?m)^($VersionKey\s*=\s*`")([^`"]+)(`".*)$"
    return $Content -replace $pattern, "`${1}$NewVersion`${3}"
}

Write-Host "Updating versions in libs.versions.toml" -ForegroundColor Cyan
if ($SdkMajorVersion) {
    Write-Host "SDK major version constraint: $SdkMajorVersion" -ForegroundColor Yellow
}
if ($DryRun) {
    Write-Host "DRY RUN - no changes will be made" -ForegroundColor Yellow
}
Write-Host ""

$versionEntries = Get-VersionEntries -Content $tomlContent
$updatedContent = $tomlContent
$hasUpdates = $false

# Find the longest key name for alignment
$maxKeyLength = ($versionEntries.Keys | Measure-Object -Property Length -Maximum).Maximum

foreach ($key in $versionEntries.Keys) {
    $entry = $versionEntries[$key]
    $currentVersion = $entry.Version
    $url = $entry.Url
    $paddedKey = $key.PadRight($maxKeyLength)

    # Determine if this is an SDK version that should be constrained
    $majorPrefix = $null
    if ($SdkMajorVersion -and $sdkVersionKeys -contains $key) {
        $majorPrefix = $SdkMajorVersion
    }

    $latestVersion = Get-LatestVersion -MetadataUrl $url -MajorVersionPrefix $majorPrefix

    if (-not $latestVersion) {
        Write-Host "$paddedKey " -NoNewline
        Write-Host "[SKIP]".PadLeft(30) -ForegroundColor Yellow
        continue
    }

    Write-Host "$paddedKey " -NoNewline
    if ($latestVersion -eq $currentVersion) {
        Write-Host "$currentVersion [UP TO DATE]".PadLeft(30) -ForegroundColor Green
    }
    else {
        Write-Host "$currentVersion -> $latestVersion [UPDATE]".PadLeft(30) -ForegroundColor Magenta
        $hasUpdates = $true
        $updatedContent = Update-VersionInToml -Content $updatedContent -VersionKey $key -NewVersion $latestVersion
    }
}

Write-Host ""

if ($hasUpdates -and -not $DryRun) {
    $updatedContent | Set-Content $tomlPath -NoNewline
    Write-Host "Updated $tomlPath" -ForegroundColor Green
}
