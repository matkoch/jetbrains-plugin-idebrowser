#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Renames the plugin IDs throughout the codebase.

.DESCRIPTION
    This script updates all references to intellijId and/or resharperId throughout
    the codebase, including:
    - File and directory names
    - Package/namespace declarations
    - Import/using statements
    - Project references
    - Configuration files

    Uses a hybrid approach:
    - Blanket replacement for full IDs in all text files
    - Targeted replacement for derived values (zone names, model names, convention prefixes)

.PARAMETER NewIntellijId
    The new IntelliJ plugin ID (e.g., "com.mycompany.myplugin").
    Must follow reverse domain notation: lowercase letters and numbers, dot-separated.
    If not provided, the current value from plugin.json is used (no changes made).
    Alias: -IntellijId

.PARAMETER NewReSharperId
    The new ReSharper plugin ID (e.g., "MyCompany.MyPlugin").
    Must be a valid C# namespace: PascalCase segments, dot-separated.
    If not provided, the current value from plugin.json is used (no changes made).
    Alias: -ReSharperId

.PARAMETER DryRun
    Preview changes without applying them.

.EXAMPLE
    ./change-plugin-ids.ps1 -IntellijId "com.acme.foobar" -ReSharperId "Acme.FooBar"

.EXAMPLE
    ./change-plugin-ids.ps1 -IntellijId "com.acme.foobar" -DryRun

.EXAMPLE
    ./change-plugin-ids.ps1 -ReSharperId "Acme.FooBar" -DryRun
    # Change only the ReSharper ID, preview first
#>

param(
    [Alias("IntellijId")]
    [string]$NewIntellijId,

    [Alias("ReSharperId")]
    [string]$NewReSharperId,

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot/settings.ps1"

# Current values come from settings.ps1 ($IntelliJId, $ReSharperId)
$currentIntellijId = $IntelliJId
$currentReSharperId = $ReSharperId

# ------------------------------------------------------------------------------
# Validation
# ------------------------------------------------------------------------------

function Test-IntellijId {
    param([string]$Id)
    # Reverse domain notation: lowercase letters/numbers, at least 2 segments
    return $Id -match '^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$'
}

function Test-ReSharperId {
    param([string]$Id)
    # Valid C# namespace: Each segment must start with uppercase letter, at least 2 segments
    # Allows: MyCompany.MyPlugin, ReSharperPlugin.Example
    # Rejects: invalid.lowercase, my.plugin
    if ($Id -notmatch '^[A-Za-z][A-Za-z0-9]*(\.[A-Za-z][A-Za-z0-9]*)+$') {
        return $false
    }
    # Check each segment starts with uppercase
    $segments = $Id -split '\.'
    foreach ($segment in $segments) {
        if ($segment[0] -cnotmatch '[A-Z]') {
            return $false
        }
    }
    return $true
}

# ------------------------------------------------------------------------------
# File/Directory Filtering
# ------------------------------------------------------------------------------

# Directories to skip during blanket operations
$script:SkipDirectories = @(
    '.git',
    '.gradle',
    '.idea',
    '.intellijPlatform',
    '.kotlin',
    'build',
    'bin',
    'obj',
    'node_modules',
    'logs',
    'artifacts'
)

# Whitelist of file extensions to process
$script:AllowedExtensions = @(
    '.kts',
    '.kt',
    '.cs',
    '.json',
    '.csproj',
    '.md',
    '.xml',
    '.slnx'
)

function Test-ShouldSkipPath {
    param([string]$Path)

    $relativePath = $Path -replace [regex]::Escape($RepoRoot), ''

    # Check if any parent directory should be skipped
    foreach ($skipDir in $script:SkipDirectories) {
        if ($relativePath -match "(^|[\\/])$([regex]::Escape($skipDir))([\\/]|$)") {
            return $true
        }
    }

    return $false
}

function Test-AllowedExtension {
    param([string]$Path)

    $extension = [System.IO.Path]::GetExtension($Path).ToLower()
    return $script:AllowedExtensions -contains $extension
}

# ------------------------------------------------------------------------------
# Change tracking
# ------------------------------------------------------------------------------

$script:Changes = @()

function Add-FileContentChange {
    param(
        [string]$Path,
        [string]$Description,
        [string]$OldValue,
        [string]$NewValue
    )
    $script:Changes += @{
        Type = "FileContent"
        Path = $Path
        Description = $Description
        OldValue = $OldValue
        NewValue = $NewValue
    }
}

function Add-FileRenameChange {
    param(
        [string]$OldPath,
        [string]$NewPath
    )
    $script:Changes += @{
        Type = "FileRename"
        OldPath = $OldPath
        NewPath = $NewPath
    }
}

function Add-DirectoryRenameChange {
    param(
        [string]$OldPath,
        [string]$NewPath
    )
    $script:Changes += @{
        Type = "DirectoryRename"
        OldPath = $OldPath
        NewPath = $NewPath
    }
}

# ------------------------------------------------------------------------------
# Blanket replacement functions
# ------------------------------------------------------------------------------

function Update-AllFileContents {
    param(
        [string]$OldPattern,
        [string]$NewPattern,
        [string]$Description
    )

    # Find all files recursively
    Get-ChildItem -Path $RepoRoot -File -Recurse -Force | ForEach-Object {
        $file = $_

        # Skip excluded paths
        if (Test-ShouldSkipPath $file.FullName) {
            return
        }

        # Only process whitelisted extensions
        if (-not (Test-AllowedExtension $file.FullName)) {
            return
        }

        # Check if file contains the pattern
        try {
            $content = Get-Content $file.FullName -Raw -ErrorAction Stop
            if ($content -and $content.Contains($OldPattern)) {
                Add-FileContentChange -Path $file.FullName `
                    -Description $Description `
                    -OldValue $OldPattern `
                    -NewValue $NewPattern
            }
        } catch {
            # Skip files we can't read
        }
    }
}

function Rename-AllMatchingFiles {
    param(
        [string]$OldPattern,
        [string]$NewPattern
    )

    # Find all files with pattern in name
    Get-ChildItem -Path $RepoRoot -File -Recurse -Force | ForEach-Object {
        $file = $_

        # Skip excluded paths
        if (Test-ShouldSkipPath $file.FullName) {
            return
        }

        if ($file.Name.Contains($OldPattern)) {
            $newName = $file.Name -replace [regex]::Escape($OldPattern), $NewPattern
            $newPath = Join-Path $file.DirectoryName $newName
            Add-FileRenameChange -OldPath $file.FullName -NewPath $newPath
        }
    }
}

function Rename-AllMatchingDirectories {
    param(
        [string]$OldPattern,
        [string]$NewPattern
    )

    # Find all directories with pattern in name (deepest first for proper renaming)
    $directories = Get-ChildItem -Path $RepoRoot -Directory -Recurse -Force |
        Where-Object { -not (Test-ShouldSkipPath $_.FullName) } |
        Where-Object { $_.Name.Contains($OldPattern) } |
        Sort-Object { $_.FullName.Length } -Descending

    foreach ($dir in $directories) {
        $newName = $dir.Name -replace [regex]::Escape($OldPattern), $NewPattern
        $newPath = Join-Path $dir.Parent.FullName $newName
        Add-DirectoryRenameChange -OldPath $dir.FullName -NewPath $newPath
    }
}

function Restructure-PackageDirectories {
    param(
        [string]$OldPath,  # e.g., "com/example/plugin"
        [string]$NewPath   # e.g., "com/mycompany/myplugin"
    )

    # Find all module-* and platform-* directories
    $moduleDirs = Get-ChildItem -Path $RepoRoot -Directory |
        Where-Object { $_.Name -like "module-*" -or $_.Name -like "platform-*" }

    foreach ($moduleDir in $moduleDirs) {
        # Check for kotlin source directories
        $kotlinPaths = @(
            "src/main/kotlin",
            "src/test/kotlin",
            "src/main/generated/kotlin"
        )

        foreach ($kotlinPath in $kotlinPaths) {
            $fullOldPath = Join-Path $moduleDir.FullName "$kotlinPath/$OldPath"
            $fullNewPath = Join-Path $moduleDir.FullName "$kotlinPath/$NewPath"

            if (Test-Path $fullOldPath) {
                Add-DirectoryRenameChange -OldPath $fullOldPath -NewPath $fullNewPath
            }
        }
    }
}

# ------------------------------------------------------------------------------
# Main update functions
# ------------------------------------------------------------------------------

function Update-IntellijId {
    param(
        [string]$OldId,
        [string]$NewId
    )

    # Blanket replacement of full ID in all file contents
    Update-AllFileContents -OldPattern $OldId -NewPattern $NewId -Description "Update intellijId"

    # Blanket rename files containing the ID
    Rename-AllMatchingFiles -OldPattern $OldId -NewPattern $NewId

    # Handle package directory restructuring (com/example/plugin -> com/mycompany/myplugin)
    $oldPath = $OldId -replace '\.', '/'
    $newPath = $NewId -replace '\.', '/'
    Restructure-PackageDirectories -OldPath $oldPath -NewPath $newPath

    # Derive convention prefix from last segment of intellijId
    $oldLastSegment = ($OldId -split '\.')[-1]
    $newLastSegment = ($NewId -split '\.')[-1]

    if ($oldLastSegment -ne $newLastSegment) {
        # Convention prefix (plugin. -> myplugin.)
        $oldConventionPrefix = $oldLastSegment.ToLower()
        $newConventionPrefix = $newLastSegment.ToLower()

        # Update references in build files
        Update-AllFileContents -OldPattern "id(`"${oldConventionPrefix}." -NewPattern "id(`"${newConventionPrefix}." -Description "Update convention plugin references"

        # Rename convention plugin files
        $conventionDir = "$RepoRoot/buildSrc/src/main/kotlin"
        if (Test-Path $conventionDir) {
            Get-ChildItem -Path $conventionDir -Filter "${oldConventionPrefix}.*.gradle.kts" | ForEach-Object {
                $newName = $_.Name -replace "^${oldConventionPrefix}\.", "${newConventionPrefix}."
                $newPath = Join-Path $_.DirectoryName $newName
                Add-FileRenameChange -OldPath $_.FullName -NewPath $newPath
            }
        }
    }
}

function Update-ReSharperId {
    param(
        [string]$OldId,
        [string]$NewId
    )

    # Blanket replacement of full ID in all file contents
    Update-AllFileContents -OldPattern $OldId -NewPattern $NewId -Description "Update resharperId"

    # Blanket rename files containing the ID
    Rename-AllMatchingFiles -OldPattern $OldId -NewPattern $NewId

    # Blanket rename directories containing the ID
    Rename-AllMatchingDirectories -OldPattern $OldId -NewPattern $NewId

    # Derive values from last segment
    $oldLastSegment = ($OldId -split '\.')[-1]
    $newLastSegment = ($NewId -split '\.')[-1]

    if ($oldLastSegment -ne $newLastSegment) {
        # Targeted: Update derived patterns

        # Zone interface (IExampleZone -> IMyPluginZone)
        Update-AllFileContents -OldPattern "I${oldLastSegment}Zone" -NewPattern "I${newLastSegment}Zone" -Description "Update zone interface"

        # Zone class/file (ExampleZone -> MyPluginZone)
        Update-AllFileContents -OldPattern "${oldLastSegment}Zone" -NewPattern "${newLastSegment}Zone" -Description "Update zone class"
        Rename-AllMatchingFiles -OldPattern "${oldLastSegment}Zone" -NewPattern "${newLastSegment}Zone"

        # Test environment zone (ExampleTestEnvironmentZone -> MyPluginTestEnvironmentZone)
        Update-AllFileContents -OldPattern "${oldLastSegment}TestEnvironmentZone" -NewPattern "${newLastSegment}TestEnvironmentZone" -Description "Update test environment zone"
        Rename-AllMatchingFiles -OldPattern "${oldLastSegment}TestEnvironmentZone" -NewPattern "${newLastSegment}TestEnvironmentZone"

        # Tests assembly (ExampleTestsAssembly -> MyPluginTestsAssembly)
        Update-AllFileContents -OldPattern "${oldLastSegment}TestsAssembly" -NewPattern "${newLastSegment}TestsAssembly" -Description "Update tests assembly"
        Rename-AllMatchingFiles -OldPattern "${oldLastSegment}TestsAssembly" -NewPattern "${newLastSegment}TestsAssembly"

        # Model (ExampleModel -> MyPluginModel)
        Update-AllFileContents -OldPattern "${oldLastSegment}Model" -NewPattern "${newLastSegment}Model" -Description "Update model"
        Rename-AllMatchingFiles -OldPattern "${oldLastSegment}Model" -NewPattern "${newLastSegment}Model"
    }
}

# ------------------------------------------------------------------------------
# Execute changes
# ------------------------------------------------------------------------------

function Invoke-Changes {
    param([switch]$DryRun)

    if ($script:Changes.Count -eq 0) {
        Write-Host "No changes to apply." -ForegroundColor Yellow
        return
    }

    # Deduplicate changes (blanket approach may find same file multiple times)
    $uniqueContentChanges = @{}
    $uniqueFileRenames = @{}
    $uniqueDirRenames = @{}

    foreach ($change in $script:Changes) {
        switch ($change.Type) {
            "FileContent" {
                $key = "$($change.Path)|$($change.OldValue)|$($change.NewValue)"
                if (-not $uniqueContentChanges.ContainsKey($key)) {
                    $uniqueContentChanges[$key] = $change
                }
            }
            "FileRename" {
                $key = $change.OldPath
                if (-not $uniqueFileRenames.ContainsKey($key)) {
                    $uniqueFileRenames[$key] = $change
                }
            }
            "DirectoryRename" {
                $key = $change.OldPath
                if (-not $uniqueDirRenames.ContainsKey($key)) {
                    $uniqueDirRenames[$key] = $change
                }
            }
        }
    }

    $contentChanges = $uniqueContentChanges.Values
    $fileRenames = $uniqueFileRenames.Values
    $dirRenames = $uniqueDirRenames.Values

    if ($DryRun) {
        Write-Host ""
        Write-Host "DRY RUN - The following changes would be made:" -ForegroundColor Cyan
        Write-Host ("=" * 60) -ForegroundColor Cyan
        Write-Host ""
    }

    # 1. Apply file content changes first
    foreach ($change in $contentChanges) {
        $relativePath = $change.Path -replace [regex]::Escape($RepoRoot), '.'

        if ($DryRun) {
            Write-Host "  [Content] $relativePath" -ForegroundColor Gray
            Write-Host "            $($change.Description): '$($change.OldValue)' -> '$($change.NewValue)'" -ForegroundColor DarkGray
        } else {
            if (Test-Path $change.Path) {
                $content = Get-Content $change.Path -Raw
                if ($content -match [regex]::Escape($change.OldValue)) {
                    $content = $content -replace [regex]::Escape($change.OldValue), $change.NewValue
                    Set-Content -Path $change.Path -Value $content -NoNewline
                    Write-Host "  [Content] $relativePath - $($change.Description)" -ForegroundColor Green
                }
            }
        }
    }

    # 2. Rename files
    foreach ($change in $fileRenames) {
        $oldRelative = $change.OldPath -replace [regex]::Escape($RepoRoot), '.'
        $newRelative = $change.NewPath -replace [regex]::Escape($RepoRoot), '.'

        if ($DryRun) {
            Write-Host "  [Rename]  $oldRelative" -ForegroundColor Gray
            Write-Host "         -> $newRelative" -ForegroundColor DarkGray
        } else {
            if (Test-Path $change.OldPath) {
                # Ensure parent directory exists
                $parentDir = Split-Path -Parent $change.NewPath
                if (-not (Test-Path $parentDir)) {
                    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
                }
                Move-Item -Path $change.OldPath -Destination $change.NewPath
                Write-Host "  [Rename]  $oldRelative -> $newRelative" -ForegroundColor Green
            }
        }
    }

    # 3. Rename directories (process deepest paths first)
    $sortedDirRenames = $dirRenames | Sort-Object { $_.OldPath.Length } -Descending
    foreach ($change in $sortedDirRenames) {
        $oldRelative = $change.OldPath -replace [regex]::Escape($RepoRoot), '.'
        $newRelative = $change.NewPath -replace [regex]::Escape($RepoRoot), '.'

        if ($DryRun) {
            Write-Host "  [DirMove] $oldRelative" -ForegroundColor Gray
            Write-Host "         -> $newRelative" -ForegroundColor DarkGray
        } else {
            if (Test-Path $change.OldPath) {
                # Ensure parent directory exists
                $parentDir = Split-Path -Parent $change.NewPath
                if (-not (Test-Path $parentDir)) {
                    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
                }

                # Check if destination already exists
                if (Test-Path $change.NewPath) {
                    # Destination exists - merge contents recursively
                    # This can happen if the script was run partially before
                    Write-Host "  [DirMove] Destination exists, merging contents..." -ForegroundColor Yellow
                    
                    # Recursively move all files, creating subdirectories as needed
                    Get-ChildItem -Path $change.OldPath -Force -Recurse | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
                        $relativePath = $_.FullName.Substring($change.OldPath.Length).TrimStart([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
                        $destPath = Join-Path $change.NewPath $relativePath
                        $destDir = Split-Path -Parent $destPath
                        
                        # Ensure destination directory exists
                        if (-not (Test-Path $destDir)) {
                            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                        }
                        
                        # Move file (overwrite if destination exists - source has updated content)
                        if (Test-Path $destPath) {
                            Remove-Item -Path $destPath -Force
                        }
                        Move-Item -Path $_.FullName -Destination $destPath
                    }
                    
                    # Remove old directory tree entirely
                    if (Test-Path $change.OldPath) {
                        Remove-Item -Path $change.OldPath -Recurse -Force
                    }
                } else {
                    Move-Item -Path $change.OldPath -Destination $change.NewPath
                }
                Write-Host "  [DirMove] $oldRelative -> $newRelative" -ForegroundColor Green

                # Clean up empty parent directories
                $oldParent = Split-Path -Parent $change.OldPath
                while ($oldParent -ne $RepoRoot -and (Test-Path $oldParent)) {
                    $items = @(Get-ChildItem -Path $oldParent -Force)
                    if ($items.Count -eq 0) {
                        Remove-Item -Path $oldParent
                        $oldParent = Split-Path -Parent $oldParent
                    } else {
                        break
                    }
                }
            }
        }
    }

    if ($DryRun) {
        Write-Host ""
        Write-Host "Run without -DryRun to apply these changes." -ForegroundColor Yellow
    } else {
        Write-Host ""
        Write-Host "All changes applied successfully." -ForegroundColor Green
    }
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

# Validate that at least one ID is being changed
if (-not $NewIntellijId -and -not $NewReSharperId) {
    Write-Host "Error: At least one of -IntellijId or -ReSharperId must be provided." -ForegroundColor Red
    exit 1
}

# Validate IntellijId format
if ($NewIntellijId) {
    if (-not (Test-IntellijId $NewIntellijId)) {
        Write-Host "Error: Invalid IntelliJ ID format '$NewIntellijId'." -ForegroundColor Red
        Write-Host "       Must be reverse domain notation (e.g., 'com.mycompany.myplugin')." -ForegroundColor Red
        Write-Host "       - Lowercase letters and numbers only" -ForegroundColor Red
        Write-Host "       - At least 2 dot-separated segments" -ForegroundColor Red
        exit 1
    }
}

# Validate ReSharper ID format
if ($NewReSharperId) {
    if (-not (Test-ReSharperId $NewReSharperId)) {
        Write-Host "Error: Invalid ReSharper ID format '$NewReSharperId'." -ForegroundColor Red
        Write-Host "       Must be a valid C# namespace (e.g., 'MyCompany.MyPlugin')." -ForegroundColor Red
        Write-Host "       - PascalCase segments starting with uppercase letter" -ForegroundColor Red
        Write-Host "       - At least 2 dot-separated segments" -ForegroundColor Red
        exit 1
    }
}

# Display header
Write-Header "Rename Plugin" @{
    "Current IntelliJ ID" = $currentIntellijId
    "Current ReSharper ID" = $currentReSharperId
    "New IntelliJ ID" = if ($NewIntellijId) { $NewIntellijId } else { "(unchanged)" }
    "New ReSharper ID" = if ($NewReSharperId) { $NewReSharperId } else { "(unchanged)" }
    "Mode" = if ($DryRun) { "Dry Run" } else { "Apply Changes" }
}

# Collect changes
if ($NewIntellijId -and $NewIntellijId -ne $currentIntellijId) {
    Update-IntellijId -OldId $currentIntellijId -NewId $NewIntellijId
}

if ($NewReSharperId -and $NewReSharperId -ne $currentReSharperId) {
    Update-ReSharperId -OldId $currentReSharperId -NewId $NewReSharperId
}

# Execute
Invoke-Changes -DryRun:$DryRun

# Clean up Gradle caches (only if changes were applied)
if (-not $DryRun -and $script:Changes.Count -gt 0) {
    Write-Host ""
    Write-Step "Cleaning Gradle caches to ensure new IDs are picked up..."

    # Stop Gradle daemon (it caches PluginSettings)
    Write-Info "Stopping Gradle daemon..."
    & $Gradlew --stop 2>&1 | Out-Null

    # Remove buildSrc cache (contains compiled PluginSettings)
    $buildSrcBuild = "$RepoRoot/buildSrc/build"
    if (Test-Path $buildSrcBuild) {
        Write-Info "Removing buildSrc/build..."
        Remove-Item -Path $buildSrcBuild -Recurse -Force
    }

    # Remove protocol build cache (contains generated PluginConstants.kt)
    $protocolBuild = "$RepoRoot/protocol/build"
    if (Test-Path $protocolBuild) {
        Write-Info "Removing protocol/build..."
        Remove-Item -Path $protocolBuild -Recurse -Force
    }

    # Remove .gradle cache
    $gradleCache = "$RepoRoot/.gradle"
    if (Test-Path $gradleCache) {
        Write-Info "Removing .gradle cache..."
        Remove-Item -Path $gradleCache -Recurse -Force
    }

    Write-Success "Gradle caches cleaned"
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Run './gradlew build' to rebuild with new IDs" -ForegroundColor Gray
    Write-Host "  2. If using Visual Studio, run './scripts/clean-visualstudio.ps1'" -ForegroundColor Gray
}
