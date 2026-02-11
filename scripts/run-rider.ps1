#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Runs Rider with the plugin installed for debugging.

.DESCRIPTION
    This script launches Rider IDE with the plugin installed in a sandbox environment.
    Wrapper around `./gradlew runRider`.

.EXAMPLE
    ./scripts/run-rider.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot/settings.ps1"

Push-Location $RepoRoot
try {
    & $Gradlew runRider
} finally {
    Pop-Location
}
