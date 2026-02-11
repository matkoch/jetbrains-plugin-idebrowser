#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Cleans up ReSharper experimental hive installations and cached installers.

.DESCRIPTION
    This script removes:
    - ReSharper experimental hive installations for this plugin
    - Cached ReSharper installers
    - Plugin installations in the local JetBrains plugins repository
    - The .csproj.user marker file

    Use this to start fresh or troubleshoot installation issues.

.PARAMETER KeepInstallers
    Keep the cached ReSharper installers (useful to avoid re-downloading).

.EXAMPLE
    ./scripts/clean-visualstudio.ps1
    # Remove all installations and caches

.EXAMPLE
    ./scripts/clean-visualstudio.ps1 -KeepInstallers
    # Remove installations but keep cached installers
#>

param(
    [switch]$KeepInstallers
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\settings.ps1"

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

$SourceBasePath = "$RepoRoot\platform-resharper\src"
$UserProjectXmlFile = "$SourceBasePath\$ReSharperId\$ReSharperId.ReSharper.csproj.user"
$InstallerCacheDir = "$env:TEMP\JetBrains\Installer.Offline"
$PluginRepository = "$env:LOCALAPPDATA\JetBrains\plugins"
$JetBrainsLocalAppData = "$env:LOCALAPPDATA\JetBrains"

# ------------------------------------------------------------------------------
# Header
# ------------------------------------------------------------------------------

Write-Header "Clean Visual Studio"

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

# Remove user project file (installation marker)
Write-Step "Removing user project file"
if (Test-Path $UserProjectXmlFile) {
    Remove-Item $UserProjectXmlFile -Force
} else {
    Write-Info "Not found: $UserProjectXmlFile"
}

# Remove plugin from local repository
Write-Step "Removing plugin from local repository"
$pluginDirs = Get-ChildItem "$PluginRepository\$ReSharperId.*" -Directory -ErrorAction SilentlyContinue
if ($pluginDirs) {
    foreach ($dir in $pluginDirs) {
        Remove-Item $dir.FullName -Recurse -Force
        Write-Info "Removed $($dir.FullName)"
    }
} else {
    Write-Info "No plugin installations found in $PluginRepository"
}

# Remove ReSharper experimental hives
Write-Step "Removing ReSharper experimental hives"
$hiveDirs = @(
    Get-ChildItem "$JetBrainsLocalAppData\Installations\*$ReSharperId*" -Directory -ErrorAction SilentlyContinue
    Get-ChildItem "$JetBrainsLocalAppData\ReSharperPlatformVs*\*$ReSharperId*" -Directory -ErrorAction SilentlyContinue
)
if ($hiveDirs) {
    foreach ($dir in $hiveDirs) {
        Remove-Item $dir.FullName -Recurse -Force
        Write-Info "Removed $($dir.FullName)"
    }
} else {
    Write-Info "No experimental hives found"
}

# Remove cached installers
if (-not $KeepInstallers) {
    Write-Step "Removing cached installers"
    if (Test-Path $InstallerCacheDir) {
        $installers = Get-ChildItem "$InstallerCacheDir\*.exe" -ErrorAction SilentlyContinue
        if ($installers) {
            foreach ($file in $installers) {
                Remove-Item $file.FullName -Force
                Write-Info "Removed $($file.FullName)"
            }
        } else {
            Write-Info "No cached installers found"
        }
    } else {
        Write-Info "Installer cache directory not found"
    }
} else {
    Write-Info "Keeping cached installers (-KeepInstallers)"
}

Write-Success "Cleanup complete!"
