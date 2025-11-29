# bump-version.ps1
# Usage:
#   .\bump-version.ps1 production   - Bump minor + set tag to production (staging->production merge)
#   .\bump-version.ps1 develop      - Set tag back to develop (after production release)
#   .\bump-version.ps1 stable       - Bump stable variant (X.Y+1.0)
#   .\bump-version.ps1 major        - Bump major release (X+1.0.0)

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("production", "develop", "stable", "major")]
    [string]$Action
)

$versionFile = "VERSION"

if (-not (Test-Path $versionFile)) {
    Write-Error "VERSION file not found!"
    exit 1
}

$currentVersion = (Get-Content $versionFile -Raw).Trim()
Write-Host "Current version: $currentVersion"

# Parse version: X.Y.Z-tag
if ($currentVersion -match "^(\d+)\.(\d+)\.(\d+)-(.+)$") {
    $major = [int]$Matches[1]
    $stable = [int]$Matches[2]
    $minor = [int]$Matches[3]
    $tag = $Matches[4]
} else {
    Write-Error "Invalid version format. Expected X.Y.Z-tag"
    exit 1
}

switch ($Action) {
    "production" {
        # Bump minor version and change tag to production
        $minor++
        $tag = "production"
        Write-Host "Bumping minor version and setting tag to production"
    }
    "develop" {
        # Just change tag back to develop (for next development cycle)
        $tag = "develop"
        Write-Host "Setting tag back to develop"
    }
    "stable" {
        # Bump stable variant, reset minor to 0
        $stable++
        $minor = 0
        Write-Host "Bumping stable variant, resetting minor to 0"
    }
    "major" {
        # Bump major, reset stable and minor to 0
        $major++
        $stable = 0
        $minor = 0
        Write-Host "Bumping major release, resetting stable and minor to 0"
    }
}

$newVersion = "$major.$stable.$minor-$tag"
Write-Host "New version: $newVersion"

# Write new version
$newVersion | Out-File -FilePath $versionFile -Encoding utf8 -NoNewline

Write-Host ""
Write-Host "VERSION file updated successfully!"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  git add VERSION"
Write-Host "  git commit -m 'Bump version to $newVersion'"
Write-Host "  git push"
