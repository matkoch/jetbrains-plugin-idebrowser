<#
.SYNOPSIS
    Sets up user-level environment variables for Gradle and NuGet cache sharing.

.DESCRIPTION
    This script prompts for paths and sets GRADLE_RO_DEP_CACHE and NUGET_PACKAGES
    as user-level environment variables on Windows. This allows sharing dependency
    caches from a macOS host with a Windows VM without platform conflicts.

.EXAMPLE
    .\setup-windows-env.ps1
#>

$ErrorActionPreference = "Stop"

Write-Host "=== Windows Environment Setup for Shared Caches ===" -ForegroundColor Cyan
Write-Host ""

# --- GRADLE_RO_DEP_CACHE ---
Write-Host "Gradle Read-Only Dependency Cache" -ForegroundColor Yellow
Write-Host "This should point to the directory CONTAINING 'modules-2' (not modules-2 itself)."
Write-Host "Example: Z:\.gradle\caches"
Write-Host "macOS default location: ~/.gradle/caches"
Write-Host ""
Write-Host "The shared folder structure should be:"
Write-Host "  GRADLE_RO_DEP_CACHE\"
Write-Host "    modules-2\"
Write-Host "      files-2.1\"
Write-Host "      metadata-*\"
Write-Host ""

$currentGradleCache = [Environment]::GetEnvironmentVariable("GRADLE_RO_DEP_CACHE", "User")
if ($currentGradleCache) {
    Write-Host "Current value: $currentGradleCache" -ForegroundColor Gray
}

$gradleCachePath = Read-Host "Enter path for GRADLE_RO_DEP_CACHE (or press Enter to skip)"

if ($gradleCachePath -and $gradleCachePath.Trim() -ne "") {
    $gradleCachePath = $gradleCachePath.Trim()

    if (-not (Test-Path $gradleCachePath)) {
        Write-Host "Warning: Path does not exist: $gradleCachePath" -ForegroundColor Yellow
        $confirm = Read-Host "Set anyway? (y/n)"
        if ($confirm -ne "y") {
            Write-Host "Skipped GRADLE_RO_DEP_CACHE" -ForegroundColor Gray
            $gradleCachePath = $null
        }
    }

    if ($gradleCachePath) {
        [Environment]::SetEnvironmentVariable("GRADLE_RO_DEP_CACHE", $gradleCachePath, "User")
        Write-Host "Set GRADLE_RO_DEP_CACHE = $gradleCachePath" -ForegroundColor Green
    }
} else {
    Write-Host "Skipped GRADLE_RO_DEP_CACHE" -ForegroundColor Gray
}

Write-Host ""

# --- NUGET_PACKAGES ---
Write-Host "NuGet Packages Cache" -ForegroundColor Yellow
Write-Host "This should point to the shared NuGet packages directory from the macOS host."
Write-Host "Example: Z:\.nuget\packages"
Write-Host "macOS default location: ~/.nuget/packages"
Write-Host ""

$currentNugetCache = [Environment]::GetEnvironmentVariable("NUGET_PACKAGES", "User")
if ($currentNugetCache) {
    Write-Host "Current value: $currentNugetCache" -ForegroundColor Gray
}

$nugetCachePath = Read-Host "Enter path for NUGET_PACKAGES (or press Enter to skip)"

if ($nugetCachePath -and $nugetCachePath.Trim() -ne "") {
    $nugetCachePath = $nugetCachePath.Trim()

    if (-not (Test-Path $nugetCachePath)) {
        Write-Host "Warning: Path does not exist: $nugetCachePath" -ForegroundColor Yellow
        $confirm = Read-Host "Set anyway? (y/n)"
        if ($confirm -ne "y") {
            Write-Host "Skipped NUGET_PACKAGES" -ForegroundColor Gray
            $nugetCachePath = $null
        }
    }

    if ($nugetCachePath) {
        [Environment]::SetEnvironmentVariable("NUGET_PACKAGES", $nugetCachePath, "User")
        Write-Host "Set NUGET_PACKAGES = $nugetCachePath" -ForegroundColor Green
    }
} else {
    Write-Host "Skipped NUGET_PACKAGES" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan

$finalGradle = [Environment]::GetEnvironmentVariable("GRADLE_RO_DEP_CACHE", "User")
$finalNuget = [Environment]::GetEnvironmentVariable("NUGET_PACKAGES", "User")

Write-Host "GRADLE_RO_DEP_CACHE = $(if ($finalGradle) { $finalGradle } else { '(not set)' })"
Write-Host "NUGET_PACKAGES      = $(if ($finalNuget) { $finalNuget } else { '(not set)' })"

Write-Host ""
Write-Host "Note: You may need to restart your terminal or IDE for changes to take effect." -ForegroundColor Yellow
