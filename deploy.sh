#!/bin/bash
# Deployment script for quiz application
# Usage: ./deploy.sh dev|main|both

set -e

TARGET=$1

if [[ ! "$TARGET" =~ ^(dev|main|both)$ ]]; then
    echo "Usage: $0 dev|main|both"
    exit 1
fi

# Get current feature branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [[ ! "$CURRENT_BRANCH" =~ ^claude/.*-01AZy5cn5rESGa65BKiAQQLH$ ]]; then
    echo "❌ Current branch '$CURRENT_BRANCH' doesn't match the expected pattern"
    exit 1
fi

echo "📦 Current branch: $CURRENT_BRANCH"

# Ensure everything is committed
if [[ -n $(git status --porcelain) ]]; then
    echo "❌ Uncommitted changes detected. Please commit or stash them first."
    exit 1
fi

# Push current branch
echo "🔄 Pushing current branch..."
git push -u origin "$CURRENT_BRANCH"

deploy_to_develop() {
    echo ""
    echo "📘 Deploying to DEVELOP..."

    # Switch to develop
    git checkout develop
    git pull origin develop

    # Merge feature branch
    echo "🔀 Merging $CURRENT_BRANCH into develop..."
    git merge "$CURRENT_BRANCH" --no-edit

    # Create sync branch for pushing
    SYNC_BRANCH="claude/sync-develop-01AZy5cn5rESGa65BKiAQQLH"
    git checkout -B "$SYNC_BRANCH"

    echo "⬆️  Pushing to $SYNC_BRANCH..."
    git push -u origin "$SYNC_BRANCH" -f

    echo "✅ Develop sync branch pushed!"
    echo "   On DEV server, run:"
    echo "   cd /path/to/quiz"
    echo "   git checkout develop"
    echo "   git merge origin/$SYNC_BRANCH"
    echo "   sudo systemctl restart quiz"
}

deploy_to_main() {
    echo ""
    echo "📕 Deploying to MAIN..."

    # Switch to develop first (main should come from develop)
    git checkout develop
    git pull origin develop

    # Switch to main
    git checkout main
    git pull origin main

    # Merge develop into main
    echo "🔀 Merging develop into main..."
    git merge develop --no-edit

    # Create sync branch for pushing
    SYNC_BRANCH="claude/sync-main-01AZy5cn5rESGa65BKiAQQLH"
    git checkout -B "$SYNC_BRANCH"

    echo "⬆️  Pushing to $SYNC_BRANCH..."
    git push -u origin "$SYNC_BRANCH" -f

    echo "✅ Main sync branch pushed!"
    echo "   On PROD server, run:"
    echo "   cd /path/to/quiz"
    echo "   git checkout main"
    echo "   git merge origin/$SYNC_BRANCH"
    echo "   sudo -u postgres psql quiz_platform -f db/migrations/001_add_power_student_role.sql"
    echo "   sudo systemctl restart quiz"
}

# Execute deployment based on target
case "$TARGET" in
    dev)
        deploy_to_develop
        ;;
    main)
        deploy_to_main
        ;;
    both)
        deploy_to_develop
        deploy_to_main
        ;;
esac

# Return to original branch
echo ""
echo "🔙 Returning to $CURRENT_BRANCH..."
git checkout "$CURRENT_BRANCH"

echo ""
echo "✨ Deployment complete!"
