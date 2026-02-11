#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Runs IntelliJ IDEA with the plugin installed for debugging.

.DESCRIPTION
    This script launches IntelliJ IDEA with the plugin installed in a sandbox environment.
    Wrapper around `./gradlew runIdea`.

.EXAMPLE
    ./scripts/run-idea.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot/settings.ps1"

Push-Location $RepoRoot
try {
    & $Gradlew runIdea
} finally {
    Pop-Location
}
