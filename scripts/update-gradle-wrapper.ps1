#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Updates the Gradle wrapper to a specified version.

.DESCRIPTION
    This script updates the Gradle wrapper files (gradlew, gradlew.bat, gradle-wrapper.jar)
    to the specified version. If no version is provided, it refreshes the wrapper using
    the version in gradle-wrapper.properties.

.PARAMETER Version
    The Gradle version to update to (e.g., "8.14"). If not specified, uses the current version.

.EXAMPLE
    ./scripts/update-gradle-wrapper.ps1
    # Refreshes wrapper with current version

.EXAMPLE
    ./scripts/update-gradle-wrapper.ps1 -Version 8.14
    # Updates wrapper to Gradle 8.14
#>

param(
    [Parameter(Position = 0)]
    [string]$Version
)

. "$PSScriptRoot/settings.ps1"

$wrapperArgs = @("wrapper")
if ($Version) {
    $wrapperArgs += "--gradle-version"
    $wrapperArgs += $Version
}

Push-Location $RepoRoot
try {
    & $Gradlew @wrapperArgs
} finally {
    Pop-Location
}
