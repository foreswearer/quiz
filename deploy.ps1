#!/usr/bin/env pwsh
# Deployment script for quiz application
# Usage: ./deploy.ps1 -Target dev|main|both

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev","main","both")]
    [string]$Target
)

$ErrorActionPreference = "Stop"

# Get current feature branch
$currentBranch = git rev-parse --abbrev-ref HEAD

if ($currentBranch -notmatch '^claude/.*-01AZy5cn5rESGa65BKiAQQLH$') {
    Write-Error "Current branch '$currentBranch' doesn't match the expected pattern"
    exit 1
}

Write-Host "📦 Current branch: $currentBranch" -ForegroundColor Cyan

# Ensure everything is committed
$status = git status --porcelain
if ($status) {
    Write-Error "Uncommitted changes detected. Please commit or stash them first."
    exit 1
}

# Push current branch
Write-Host "🔄 Pushing current branch..." -ForegroundColor Yellow
git push -u origin $currentBranch

function Deploy-ToDevelop {
    Write-Host "`n📘 Deploying to DEVELOP..." -ForegroundColor Blue

    # Switch to develop
    git checkout develop
    git pull origin develop

    # Merge feature branch
    Write-Host "🔀 Merging $currentBranch into develop..." -ForegroundColor Yellow
    git merge $currentBranch --no-edit

    # Create sync branch for pushing
    $syncBranch = "claude/sync-develop-01AZy5cn5rESGa65BKiAQQLH"
    git checkout -B $syncBranch

    Write-Host "⬆️  Pushing to $syncBranch..." -ForegroundColor Yellow
    git push -u origin $syncBranch -f

    Write-Host "✅ Develop sync branch pushed!" -ForegroundColor Green
    Write-Host "   On DEV server, run:" -ForegroundColor Cyan
    Write-Host "   cd /path/to/quiz" -ForegroundColor White
    Write-Host "   git checkout develop" -ForegroundColor White
    Write-Host "   git merge origin/$syncBranch" -ForegroundColor White
    Write-Host "   sudo systemctl restart quiz" -ForegroundColor White
}

function Deploy-ToMain {
    Write-Host "`n📕 Deploying to MAIN..." -ForegroundColor Red

    # Switch to develop first (main should come from develop)
    git checkout develop
    git pull origin develop

    # Switch to main
    git checkout main
    git pull origin main

    # Merge develop into main
    Write-Host "🔀 Merging develop into main..." -ForegroundColor Yellow
    git merge develop --no-edit

    # Create sync branch for pushing
    $syncBranch = "claude/sync-main-01AZy5cn5rESGa65BKiAQQLH"
    git checkout -B $syncBranch

    Write-Host "⬆️  Pushing to $syncBranch..." -ForegroundColor Yellow
    git push -u origin $syncBranch -f

    Write-Host "✅ Main sync branch pushed!" -ForegroundColor Green
    Write-Host "   On PROD server, run:" -ForegroundColor Cyan
    Write-Host "   cd /path/to/quiz" -ForegroundColor White
    Write-Host "   git checkout main" -ForegroundColor White
    Write-Host "   git merge origin/$syncBranch" -ForegroundColor White
    Write-Host "   sudo -u postgres psql quiz_platform -f db/migrations/001_add_power_student_role.sql" -ForegroundColor White
    Write-Host "   sudo systemctl restart quiz" -ForegroundColor White
}

# Execute deployment based on target
switch ($Target) {
    "dev" {
        Deploy-ToDevelop
    }
    "main" {
        Deploy-ToMain
    }
    "both" {
        Deploy-ToDevelop
        Deploy-ToMain
    }
}

# Return to original branch
Write-Host "`n🔙 Returning to $currentBranch..." -ForegroundColor Cyan
git checkout $currentBranch

Write-Host "`n✨ Deployment complete!" -ForegroundColor Green
