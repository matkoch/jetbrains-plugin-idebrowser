#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Shared settings for build scripts.

.DESCRIPTION
    This script provides common variables and utilities used by other scripts.
    Import it with: . "$PSScriptRoot/settings.ps1"
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Repository root
$script:RepoRoot = Resolve-Path "$PSScriptRoot/.."

# Gradle wrapper path (compatible with Windows PowerShell 5.1 and PowerShell Core)
$script:IsWindowsOS = ($env:OS -eq "Windows_NT") -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)
$script:Gradlew = if ($IsWindowsOS) {
    "$RepoRoot/gradlew.bat"
} else {
    "$RepoRoot/gradlew"
}

# Read plugin IDs from plugin.json
$script:PluginConfig = Get-Content "$RepoRoot/plugin.json" | ConvertFrom-Json

$script:IntelliJId = $PluginConfig.intellijId
$script:ReSharperId = $PluginConfig.resharperId

# ------------------------------------------------------------------------------
# Output helpers for consistent formatting
# ------------------------------------------------------------------------------

function Write-Header {
    param(
        [Parameter(Mandatory)][string]$Title,
        [hashtable]$Parameters
    )
    $separator = "=" * $Title.Length
    Write-Host ""
    Write-Host $Title -ForegroundColor Cyan
    Write-Host $separator -ForegroundColor Cyan
    if ($Parameters -and $Parameters.Count -gt 0) {
        Write-Host ""
        $maxKeyLength = ($Parameters.Keys | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum
        foreach ($key in $Parameters.Keys) {
            $label = "${key}:"
            Write-Info ("{0,-$($maxKeyLength + 1)}  {1}" -f $label, $Parameters[$key])
        }
    }
    Write-Host ""
}

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host ">> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "<< $Message" -ForegroundColor Green
}

function Write-Info {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "$Message" -ForegroundColor Gray
}

function Invoke-Exe {
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Executable,

        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments,

        [int[]]$ValidExitCodes = @(0),

        [switch]$UseStartProcess
    )

    # Build display string with proper quoting for args containing spaces
    $displayArgs = ($Arguments | ForEach-Object { 
        if ($_ -match '\s') { "`"$_`"" } else { $_ } 
    }) -join ' '
    Write-Info "Invoke: $Executable $displayArgs"

    if ($UseStartProcess) {
        $process = Start-Process -FilePath $Executable -ArgumentList $Arguments -NoNewWindow -PassThru -Wait
        $exitCode = $process.ExitCode
    } else {
        & $Executable @Arguments
        $exitCode = $LASTEXITCODE
    }
    
    if ($exitCode -notin $ValidExitCodes) {
        throw "'$Executable $displayArgs' failed with exit code $exitCode"
    }
}
