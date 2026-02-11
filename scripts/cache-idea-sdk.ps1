#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Downloads and caches the IntelliJ IDEA SDK.

.DESCRIPTION
    This script downloads the IntelliJ IDEA SDK by resolving the platform-idea
    module dependencies. Used by CI to populate the Gradle cache.

.EXAMPLE
    ./scripts/cache-idea-sdk.ps1
#>

. "$PSScriptRoot/settings.ps1"

Push-Location $RepoRoot
try {
    & $Gradlew :platform-idea:dependencies --configuration compileClasspath
} finally {
    Pop-Location
}
