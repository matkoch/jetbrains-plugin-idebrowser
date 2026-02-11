#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Runs Visual Studio with ReSharper in an experimental hive for plugin debugging.

.DESCRIPTION
    This script sets up and launches Visual Studio with ReSharper installed in an
    experimental hive, allowing you to debug your ReSharper plugin without affecting
    your main VS/ReSharper installation.

    On first run (or with -Clean), the script will:
    1. Download the ReSharper installer matching your SDK version
    2. Install ReSharper into an experimental Visual Studio hive
    3. Register your plugin in the experimental installation
    4. Build the plugin and launch Visual Studio

    Subsequent runs skip installation and just build + launch.

.PARAMETER Version
    Plugin version to use for development. Default: "9999.0.0"

.PARAMETER Configuration
    Build configuration. Default: "Debug"
    Valid values: Debug, Release

.PARAMETER LogLevel
    ReSharper logging level. Default: "Trace"
    Valid values: Trace, Verbose, Info, Warning, Error, Off

.PARAMETER VsChannel
    Visual Studio channel to use. Default: "Any"
    Valid values: Release, Preview, Insider, Any

.PARAMETER Clean
    Force a fresh installation by removing the .csproj.user marker file.

.PARAMETER SkipBuild
    Skip the build step and just launch VS with the existing plugin.

.EXAMPLE
    ./scripts/run-resharper.ps1
    # Run with defaults - installs on first run, then just builds and launches

.EXAMPLE
    ./scripts/run-resharper.ps1 -Clean
    # Force a fresh ReSharper installation

.EXAMPLE
    ./scripts/run-resharper.ps1 -LogLevel Info -SkipBuild
    # Launch quickly with less verbose logging

.EXAMPLE
    ./scripts/run-resharper.ps1 -VsChannel Preview
    # Use Visual Studio Preview instead of Release
#>

param(
    [string]$Version = "9999.0.0",

    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Debug",

    [ValidateSet("Trace", "Verbose", "Info", "Warning", "Error", "Off")]
    [string]$LogLevel = "Trace",

    [ValidateSet("Release", "Preview", "Insider", "Any")]
    [string]$VsChannel = "Any",

    [switch]$Clean,

    [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\settings.ps1"

if (-not $IsWindowsOS) {
    throw "This script requires Windows. Use run-rider.ps1 for cross-platform Rider debugging."
}

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

$SourceBasePath = "$RepoRoot\platform-resharper\src"
$ProjectPath = "$SourceBasePath\$ReSharperId\$ReSharperId.ReSharper.csproj"
$OutputDirectory = "$SourceBasePath\$ReSharperId\bin\$Configuration"
$SdkPropsFile = "$RepoRoot\build\DotNetSdkPath.Generated.props"
$LogsDirectory = "$RepoRoot\logs"

$LogFile = "$LogsDirectory\ReSharper.log"
$UserProjectXmlFile = "$SourceBasePath\$ReSharperId\$ReSharperId.ReSharper.csproj.user"

# TODO: .NET SDK 10.0.200
$NuGetExe = "$RepoRoot\..\external\resharper-rider-plugin\content\tools\nuget.exe"
$InstallerCacheDir = "$env:TEMP\JetBrains\Installer.Offline"

# ------------------------------------------------------------------------------
# Header
# ------------------------------------------------------------------------------

Write-Header "Run ReSharper" @{
    Version       = $Version
    Configuration = $Configuration
    LogLevel      = $LogLevel
}

# ------------------------------------------------------------------------------
# Detect Visual Studio
# ------------------------------------------------------------------------------

Write-Step "Detecting Visual Studio"

$vswherePath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswherePath)) {
    throw "vswhere.exe not found. Is Visual Studio installed?"
}

$vsProducts = @(
    "Microsoft.VisualStudio.Product.Community"
    "Microsoft.VisualStudio.Product.Professional"
    "Microsoft.VisualStudio.Product.Enterprise"
)
$vsInstances = & $vswherePath -format json -products $vsProducts -prerelease | ConvertFrom-Json
if (-not $vsInstances) {
    throw "No Visual Studio installation found."
}

$vs = @($vsInstances) |
    Where-Object { $VsChannel -eq "Any" -or $_.channelId -match $VsChannel } |
    Sort-Object -Property installationVersion -Descending |
    Select-Object -First 1

if (-not $vs) {
    $available = ($vsInstances | ForEach-Object { "$($_.displayName) [$($_.channelId)]" }) -join ', '
    throw "No Visual Studio '$VsChannel' installation found. Available: $available"
}

$DevEnvPath = "$($vs.installationPath)\Common7\IDE\devenv.exe"
if (-not (Test-Path $DevEnvPath)) {
    throw "devenv.exe not found at $DevEnvPath"
}

$MSBuildPath = "$($vs.installationPath)\MSBuild\Current\Bin\MSBuild.exe"
if (-not (Test-Path $MSBuildPath)) {
    throw "MSBuild.exe not found at $MSBuildPath"
}

$VsMajorVersion = ($vs.installationVersion -split '\.')[0]
$VsInstanceId = $vs.instanceId

Write-Info "$($vs.displayName) ($($vs.installationVersion))"

# ------------------------------------------------------------------------------
# Handle -Clean flag
# ------------------------------------------------------------------------------

if ($Clean -and (Test-Path $UserProjectXmlFile)) {
    Write-Step "Cleaning previous installation"
    Remove-Item $UserProjectXmlFile -Force
    Write-Info "Removed $UserProjectXmlFile"
}

# ------------------------------------------------------------------------------
# First-time installation
# ------------------------------------------------------------------------------

if (-not (Test-Path $UserProjectXmlFile)) {
    # Read SDK version
    Write-Step "Reading SDK version"
    if (-not (Test-Path $SdkPropsFile)) {
        Write-Host ""
        Write-Info "SDK props file not found: $SdkPropsFile"
        Write-Host ""
        Write-Info "This file is generated by Gradle. Run the following command first:"
        Write-Host ""
        Write-Host "  $Gradlew :prepareDotNetBuildProps" -ForegroundColor White
        Write-Host ""
        Write-Info "Or run any Gradle build task (e.g., ./gradlew buildPlugin)"
        Write-Host ""
        throw "DotNetSdkPath.Generated.props not found. Run Gradle to generate it."
    }

    $SdkPropsXml = [xml](Get-Content $SdkPropsFile)
    $SdkVersionNode = $SdkPropsXml.SelectSingleNode(".//SdkVersion")
    if (-not $SdkVersionNode) {
        throw "SdkVersion not found in $SdkPropsFile"
    }

    $SdkVersion = $SdkVersionNode.InnerText
    $VersionParts = $SdkVersion.Split(".")
    $MajorVersion = "$($VersionParts[0]).$($VersionParts[1])"
    Write-Info "SDK version: $SdkVersion (major: $MajorVersion)"

    # Download ReSharper installer
    Write-Step "Fetching ReSharper release info"
    $ReleaseUrl = "https://data.services.jetbrains.com/products/releases?code=RSU&type=eap&type=release&majorVersion=$MajorVersion"
    $VersionEntry = (Invoke-WebRequest -UseBasicParsing $ReleaseUrl | ConvertFrom-Json).RSU[0]
    $DownloadLink = [uri]($VersionEntry.downloads.windows.link.replace(".exe", ".Checked.exe"))
    Write-Info "Release: $($VersionEntry.version) ($($VersionEntry.type))"

    $InstallerFile = "$InstallerCacheDir\$($DownloadLink.Segments[-1])"

    if (-not (Test-Path $InstallerFile)) {
        Write-Step "Downloading ReSharper installer"
        Write-Info "From: $DownloadLink"
        Write-Info "To: $InstallerFile"

        New-Item -ItemType Directory -Path $InstallerCacheDir -Force | Out-Null
        Start-BitsTransfer -Source $DownloadLink -Destination $InstallerFile
    } else {
        Write-Info "Using cached installer: $InstallerFile"
    }

    # Install ReSharper to experimental hive
    Write-Step "Installing ReSharper to experimental hive"
    $InstallerArgs = @("/VsVersion=$VsMajorVersion.0", "/SpecificProductNames=ReSharper", "/Hive=$ReSharperId", "/Silent=True")
    Invoke-Exe $InstallerFile @InstallerArgs -UseStartProcess

    # Find installation directory
    Write-Step "Configuring plugin registration"
    $SearchPath = "$env:LOCALAPPDATA\JetBrains\ReSharperPlatformVs$VsMajorVersion\vAny_$VsInstanceId$ReSharperId\NuGet.Config"
    if (-not (Test-Path $SearchPath)) {
        throw "Installation directory not found at $SearchPath"
    }
    $InstallationDirectory = (Get-Item $SearchPath).Directory
    Write-Info "Installation: $InstallationDirectory"

    # Register plugin in packages.config
    $PackagesConfigPath = "$InstallationDirectory\packages.config"
    $PackagesXml = if (Test-Path $PackagesConfigPath) {
        [xml](Get-Content $PackagesConfigPath)
    } else {
        [xml]'<?xml version="1.0" encoding="utf-8"?><packages></packages>'
    }

    if ($null -eq $PackagesXml.SelectSingleNode(".//package[@id='$ReSharperId']/@id")) {
        $PluginNode = $PackagesXml.CreateElement('package')
        $PluginNode.setAttribute("id", $ReSharperId)
        $PluginNode.setAttribute("version", $Version)
        $PackagesXml.DocumentElement.AppendChild($PluginNode) > $null
        $PackagesXml.Save($PackagesConfigPath)
    }

    # Create .csproj.user file
    Write-Step "Creating user project file"
    $HostIdentifier = "$($InstallationDirectory.Parent.Name)_$($InstallationDirectory.Name.Split('_')[-1])"
    $UserProjectContent = @"
<Project>
  <PropertyGroup Condition="'`$(MSBuildRuntimeType)' == 'Full'">
    <HostFullIdentifier>$HostIdentifier</HostFullIdentifier>
  </PropertyGroup>
</Project>
"@
    Set-Content -Path $UserProjectXmlFile -Value $UserProjectContent

    # Build and package plugin
    Write-Step "Building and packaging plugin"
    Invoke-Exe $MSBuildPath /t:Restore`;Rebuild`;Pack $ProjectPath /v:minimal /p:PackageVersion=$Version /p:PackageOutputPath="$OutputDirectory"

    # Install plugin to local repository
    Write-Step "Installing plugin to local repository"
    $PluginRepository = "$env:LOCALAPPDATA\JetBrains\plugins"
    Remove-Item "$PluginRepository\$ReSharperId.$Version" -Recurse -ErrorAction Ignore
    $NuGetArgs = @("install", $ReSharperId, "-OutputDirectory", $PluginRepository, "-Source", $OutputDirectory, "-DependencyVersion", "Ignore")
    Invoke-Exe $NuGetExe @NuGetArgs

    # Re-run installer to pick up plugin
    Write-Step "Finalizing ReSharper installation"
    Invoke-Exe $InstallerFile @InstallerArgs -UseStartProcess

} else {
    Write-Info "Plugin already installed (marker file exists)"
    Write-Info "Use -Clean to force reinstallation"

    # Build plugin
    if (-not $SkipBuild) {
        Write-Step "Building plugin"
        Invoke-Exe $MSBuildPath /t:Restore`;Rebuild $ProjectPath /v:minimal
    } else {
        Write-Info "Skipping build (-SkipBuild)"
    }
}

# ------------------------------------------------------------------------------
# Launch Visual Studio
# ------------------------------------------------------------------------------

Write-Step "Launching Visual Studio"

New-Item -ItemType Directory -Path $LogsDirectory -Force | Out-Null

$DevEnvArgs = @("/rootSuffix", $ReSharperId, "/ReSharper.Internal", "/ReSharper.LogFile", $LogFile, "/ReSharper.LogLevel", $LogLevel)
Invoke-Exe $DevEnvPath @DevEnvArgs
