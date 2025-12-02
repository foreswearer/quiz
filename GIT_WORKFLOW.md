# Git Workflow Guide

This document describes the Git workflow for developing and releasing features in the Quiz Platform.

## Overview

- **`develop` branch**: Development and staging (deploys to port 8001)
- **`main` branch**: Production (deploys to port 8000)
- **Amend commits**: Keep history clean during development
- **Version bumps**: Only when releasing to production

---

## Phase 1: Development (on `develop` branch)

### First Commit (normal)

When starting a new feature:

**PyCharm UI:**
1. `Ctrl+K` (Commit window)
2. Check the files you changed
3. Write message: `WIP: description of feature`
4. Click **Commit and Push**

**Command line:**
```powershell
git add .
git commit -m "WIP: description of feature"
git push origin develop
```

---

### Subsequent Changes (amend)

For all changes while developing the same feature:

**PyCharm UI:**
1. `Ctrl+K` (Commit window)
2. Check your changed files
3. ☑️ Check **"Amend commit"** checkbox (bottom of commit window)
4. Click **Commit and Push**
5. PyCharm will warn about force push → Click **Force Push**

**Command line:**
```powershell
git add .
git commit --amend --no-edit
git push origin develop --force
```

> **Repeat** this until everything works on staging.

---

### Final Amend (clean message)

When the feature is complete and tested:

**PyCharm UI:**
1. `Ctrl+K`
2. ☑️ **Amend commit**
3. Change message to something clean: `Add feature X and Y`
4. **Commit and Push** → **Force Push**

**Command line:**
```powershell
git add .
git commit --amend -m "Add feature X and Y"
git push origin develop --force
```

---

## Phase 2: Release to Production

### Step 1: Bump Version

```powershell
.\bump-version.ps1 production
```

This changes `VERSION` from `X.Y.Z-develop` to `X.Y.(Z+1)-production`

---

### Step 2: Commit Version Bump

**PyCharm UI:**
1. `Ctrl+K`
2. Check `VERSION` file only
3. Message: `Bump version to X.Y.Z-production`
4. **Commit and Push** (normal, NOT amend!)

**Command line:**
```powershell
git add VERSION
git commit -m "Bump version to X.Y.Z-production"
git push origin develop
```

---

### Step 3: Merge to Main

**PyCharm UI:**
1. Bottom-right corner → click branch name (`develop`)
2. Click `main` → **Checkout**
3. Right-click `develop` in the branch list → **Merge 'develop' into 'main'**
4. `Ctrl+Shift+K` → **Push**

**Command line:**
```powershell
git checkout main
git merge develop
git push origin main
```

🚀 **Production deploys automatically via GitHub Actions!**

---

### Step 4: Back to Development

**PyCharm UI:**
1. Click branch (bottom-right) → **develop** → **Checkout**

**Command line:**
```powershell
git checkout develop
.\bump-version.ps1 develop
git add VERSION
git commit -m "Start development on X.Y.Z-develop"
git push origin develop
```

---

## Quick Reference

### PyCharm Shortcuts

| Action | Shortcut |
|--------|----------|
| Commit window | `Ctrl+K` |
| Push | `Ctrl+Shift+K` |
| Update project (pull) | `Ctrl+T` |
| Show Git log | `Alt+9` |

### Command Line Cheatsheet

| Action | Command |
|--------|---------|
| Normal commit | `git commit -m "message"` |
| Amend (keep message) | `git commit --amend --no-edit` |
| Amend (new message) | `git commit --amend -m "new message"` |
| Push | `git push origin <branch>` |
| Force push | `git push origin <branch> --force` |
| Switch branch | `git checkout <branch>` |
| Merge | `git merge <source-branch>` |

### Version Bump Commands

| Action | Command |
|--------|---------|
| Release to production | `.\bump-version.ps1 production` |
| Back to development | `.\bump-version.ps1 develop` |
| Bump stable (X.Y+1.0) | `.\bump-version.ps1 stable` |
| Bump major (X+1.0.0) | `.\bump-version.ps1 major` |

---

## Example: Complete Feature Cycle

```powershell
# 1. Start feature
git checkout develop
git add .
git commit -m "WIP: add user avatars"
git push origin develop

# 2. Iterate (repeat as needed)
git add .
git commit --amend --no-edit
git push origin develop --force

# 3. Finalize
git commit --amend -m "Add user avatar support"
git push origin develop --force

# 4. Release
.\bump-version.ps1 production
git add VERSION
git commit -m "Bump version to 1.0.5-production"
git push origin develop

# 5. Deploy to production
git checkout main
git merge develop
git push origin main

# 6. Continue development
git checkout develop
.\bump-version.ps1 develop
git add VERSION
git commit -m "Start development on 1.0.5-develop"
git push origin develop
```

---

## Database Sync

If staging database is out of sync with production:

**Option 1: GitHub Actions**
- Go to repo → Actions → "Sync Staging DB from Production" → Run workflow

**Option 2: SSH**
```bash
ssh ramiro_rego@quiz.ramiro-rego.com
./sync-db-to-staging.sh
```

---

## Important Rules

1. **Never push untested code to `main`** - always test on staging first
2. **Use amend** to keep history clean during development
3. **Bump version** before merging to main
4. **Force push** is only safe on `develop` when using amend
5. **Never force push to `main`**
