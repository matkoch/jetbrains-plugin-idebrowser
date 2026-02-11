#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Prepares a new release by patching the changelog, committing, tagging, and pushing.

.DESCRIPTION
    This script automates the release preparation process:
    1. Patches the CHANGELOG.md with the specified version
    2. Commits the changelog with a conventional commit message
    3. Creates a git tag for the version
    4. Pushes the commit and tag to origin

.PARAMETER Version
    The version to release (e.g., 1.0.0). Must follow semver format.

.EXAMPLE
    ./scripts/prepare-release.ps1 -Version 1.0.0
    # Prepares release for version 1.0.0

.EXAMPLE
    ./scripts/prepare-release.ps1 -Version 2.1.0-beta.1
    # Prepares a pre-release version
#>

param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Version
)

. "$PSScriptRoot/settings.ps1"

# Validate version format (semver)
if ($Version -notmatch '^\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?$') {
    throw "Invalid version format: $Version. Expected semver format (e.g., 1.0.0 or 1.0.0-beta.1)"
}

# Check for uncommitted changes
$status = git status --porcelain
if ($status) {
    throw "Working directory has uncommitted changes. Please commit or stash them first."
}

# Check if tag already exists
$existingTag = git tag -l $Version
if ($existingTag) {
    throw "Tag '$Version' already exists."
}

# ------------------------------------------------------------------------------
# Header
# ------------------------------------------------------------------------------

Write-Header "Prepare Release" @{
    Version = $Version
}

# ------------------------------------------------------------------------------
# Patch changelog
# ------------------------------------------------------------------------------

Write-Step "Patching CHANGELOG.md"
Push-Location $RepoRoot
try {
    & $Gradlew patchChangelog "-Pversion=$Version"
    if ($LASTEXITCODE -ne 0) {
        throw "patchChangelog failed with exit code $LASTEXITCODE"
    }
} finally {
    Pop-Location
}
Write-Success "Changelog patched"

# ------------------------------------------------------------------------------
# Commit and tag
# ------------------------------------------------------------------------------

Write-Step "Committing changelog"
git add "$RepoRoot/CHANGELOG.md"
git commit -m "chore: release $Version"
if ($LASTEXITCODE -ne 0) {
    throw "git commit failed with exit code $LASTEXITCODE"
}
Write-Success "Changelog committed"

# Create tag
Write-Step "Creating tag $Version"
git tag $Version
if ($LASTEXITCODE -ne 0) {
    throw "git tag failed with exit code $LASTEXITCODE"
}
Write-Success "Tag created"

# ------------------------------------------------------------------------------
# Push to origin
# ------------------------------------------------------------------------------

Write-Step "Pushing to origin"
git push origin HEAD
if ($LASTEXITCODE -ne 0) {
    throw "git push failed with exit code $LASTEXITCODE"
}
git push origin $Version
if ($LASTEXITCODE -ne 0) {
    throw "git push tag failed with exit code $LASTEXITCODE"
}
Write-Success "Pushed to origin"

Write-Success "Release prepared successfully!"
Write-Info "The publish workflow will be triggered automatically."
