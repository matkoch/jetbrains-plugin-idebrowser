#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Downloads and caches the Rider SDK.

.DESCRIPTION
    This script downloads the Rider SDK by initializing the IntelliJ Platform plugin.
    Used by CI to populate the Gradle cache.

.EXAMPLE
    ./scripts/cache-rider-sdk.ps1
#>

. "$PSScriptRoot/settings.ps1"

Push-Location $RepoRoot
try {
    & $Gradlew :initializeIntellijPlatformPlugin
} finally {
    Pop-Location
}
