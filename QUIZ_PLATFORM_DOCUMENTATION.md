# Quiz Platform - Complete Project Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Technology Stack](#technology-stack)
4. [Environment Setup](#environment-setup)
5. [File Structure](#file-structure)
6. [Database Schema](#database-schema)
7. [API Endpoints](#api-endpoints)
8. [Frontend Features](#frontend-features)
9. [Git Workflow](#git-workflow)
10. [CI/CD Pipeline](#cicd-pipeline)
11. [Version Management](#version-management)
12. [Common Operations](#common-operations)
13. [Troubleshooting](#troubleshooting)
14. [Current State](#current-state)
15. [Continuation Prompt](#continuation-prompt)

---

## Project Overview

**Name**: Cloud Digital Leader Quiz Platform  
**Purpose**: Web-based quiz/exam platform for students and teachers preparing for Google Cloud Digital Leader certification  
**Repository**: https://github.com/foreswearer/quiz  
**Production URL**: https://quiz.ramiro-rego.com (port 8000)  
**Staging URL**: http://quiz.ramiro-rego.com:8001 (port 8001)  
**Server**: VPS at quiz.ramiro-rego.com (IP: 35.188.89.142, user: `ramiro_rego`)

### Key Features
- Student/Teacher role-based access via DNI (Spanish ID)
- Take quizzes with multiple-choice questions
- Create random tests from question bank
- View attempts history with pagination (5 per page)
- Score visualization with charts
- Teacher dashboard with analytics
- Test management (create, rename, delete)
- Podium/leaderboard for each test
- Dark/Light theme toggle
- Dynamic version banner with disclaimer

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              ARCHITECTURE                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐                   │
│  │   Browser   │────▶│   NGINX     │────▶│   Uvicorn   │                   │
│  │  (Vanilla   │     │  (Reverse   │     │  (ASGI      │                   │
│  │   JS)       │     │   Proxy)    │     │   Server)   │                   │
│  └─────────────┘     └─────────────┘     └──────┬──────┘                   │
│                                                  │                          │
│                                                  ▼                          │
│                                          ┌─────────────┐                   │
│                                          │   FastAPI   │                   │
│                                          │  (Python    │                   │
│                                          │   Backend)  │                   │
│                                          └──────┬──────┘                   │
│                                                  │                          │
│                                                  ▼                          │
│                                          ┌─────────────┐                   │
│                                          │ PostgreSQL  │                   │
│                                          │  Database   │                   │
│                                          └─────────────┘                   │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                           THREE ENVIRONMENTS                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  LOCAL (Development)                                                        │
│  ├── Path: c:\projects\quiz                                                │
│  ├── Branch: develop                                                        │
│  ├── URL: http://localhost:8000                                            │
│  └── Database: quiz_platform (local PostgreSQL)                            │
│                                                                             │
│  STAGING (Testing)                                                          │
│  ├── Path: /home/ramiro_rego/quiz-backend-staging                          │
│  ├── Branch: develop                                                        │
│  ├── URL: http://quiz.ramiro-rego.com:8001                                 │
│  ├── Database: quiz_platform_staging                                        │
│  └── Service: quiz-backend-staging.service                                 │
│                                                                             │
│  PRODUCTION (Live)                                                          │
│  ├── Path: /home/ramiro_rego/quiz-backend                                  │
│  ├── Branch: main                                                           │
│  ├── URL: https://quiz.ramiro-rego.com                                     │
│  ├── Database: quiz_platform                                                │
│  └── Service: quiz-backend.service                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **User Request**: Browser sends HTTP request
2. **NGINX**: Receives request on port 80/443, forwards to Uvicorn
3. **Uvicorn**: ASGI server running FastAPI application
4. **FastAPI**: Handles routing, validation, business logic
5. **PostgreSQL**: Stores all persistent data
6. **Response**: JSON data returned to browser
7. **Vanilla JS**: Renders UI dynamically based on response

---

## Technology Stack

### Backend
| Component | Technology | Purpose |
|-----------|------------|---------|
| Framework | FastAPI | REST API, async support, auto-docs |
| Server | Uvicorn | ASGI server for production |
| Database | PostgreSQL | Relational data storage |
| DB Driver | psycopg2 | Python PostgreSQL adapter |
| Validation | Pydantic | Request/response schemas |

### Frontend
| Component | Technology | Purpose |
|-----------|------------|---------|
| JavaScript | Vanilla JS (ES6+) | No framework, pure JS |
| Styling | CSS3 | Custom styles with CSS variables |
| Charts | Chart.js | Score visualization |
| Templating | Jinja2 | Server-side HTML rendering |

### DevOps
| Component | Technology | Purpose |
|-----------|------------|---------|
| Version Control | Git + GitHub | Code management |
| CI/CD | GitHub Actions | Automated testing and deployment |
| Web Server | NGINX | Reverse proxy, SSL termination |
| Process Manager | systemd | Service management |
| Linting | Ruff | Python code quality |

---

## Environment Setup

### Local Development (Windows)

```powershell
# Clone repository
git clone https://github.com/foreswearer/quiz.git
cd quiz

# Create virtual environment
python -m venv venv
.\venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set up local PostgreSQL database
# Create database: quiz_platform
# Run schema: psql -U postgres -d quiz_platform -f schema.sql

# Run development server
uvicorn main:app --reload --port 8000
```

### Server Access

```bash
# SSH to server
ssh ramiro_rego@quiz.ramiro-rego.com

# Check service status
sudo systemctl status quiz-backend.service           # Production
sudo systemctl status quiz-backend-staging.service   # Staging

# View logs
sudo journalctl -u quiz-backend.service -n 50 --no-pager
sudo journalctl -u quiz-backend-staging.service -n 50 --no-pager

# Database access
sudo -u postgres psql quiz_platform           # Production
sudo -u postgres psql quiz_platform_staging   # Staging
```

---

## File Structure

```
c:\projects\quiz\
│
├── .github/
│   └── workflows/
│       ├── ci-cd.yml                 # Main CI/CD pipeline
│       └── sync-staging-db.yml       # Manual DB sync workflow
│
├── app/
│   ├── __init__.py
│   ├── api.py                        # All API endpoints (1400+ lines)
│   ├── db.py                         # Database connection helper
│   ├── config.py                     # Configuration (DB credentials, etc.)
│   └── schemas.py                    # Pydantic models for request validation
│
├── templates/
│   ├── portal.html                   # Main landing page (DNI entry, tests, attempts)
│   ├── quiz.html                     # Quiz-taking page
│   └── dashboard.html                # Teacher analytics dashboard
│
├── static/
│   ├── css/
│   │   ├── base.css                  # Shared styles, theme variables
│   │   ├── portal.css                # Portal-specific styles
│   │   ├── quiz.css                  # Quiz page styles
│   │   └── dashboard.css             # Dashboard styles
│   │
│   └── js/
│       ├── portal.js                 # Portal logic (746 lines)
│       ├── quiz.js                   # Quiz-taking logic
│       └── dashboard.js              # Teacher dashboard logic
│
├── main.py                           # FastAPI app entry point
├── schema.sql                        # Database schema + seed data
├── requirements.txt                  # Python dependencies
├── VERSION                           # Version file (e.g., "1.0.3-develop")
├── deploy.sh                         # Production deployment script
└── deploy_staging.sh                 # Staging deployment script
```

### Key Files Explained

#### `app/api.py`
The heart of the backend. Contains all REST endpoints:
- Health and version checks
- Test CRUD operations
- Attempt management
- Scoring logic
- Analytics and statistics
- Teacher dashboard data

#### `static/js/portal.js`
Main frontend logic:
- Cookie-based session management (DNI stored in cookie)
- Theme toggle (light/dark)
- Test selection and navigation
- Attempts table with pagination
- Charts for score visualization
- Teacher panel functionality

#### `VERSION`
Simple text file containing version string:
```
MAJOR.STABLE.MINOR-ENVIRONMENT
```
Example: `1.0.3-develop` or `1.0.3-production`

#### `.github/workflows/ci-cd.yml`
Automated pipeline:
1. **Quality Check**: Runs Ruff linting and pytest
2. **Deploy Staging**: On push to `develop`
3. **Deploy Production**: On push to `main`

---

## Database Schema

```sql
┌─────────────────────────────────────────────────────────────────────────────┐
│                            DATABASE SCHEMA                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  app_user                                                                   │
│  ├── id (PK)                                                               │
│  ├── dni (UNIQUE) ─────────────────────────────────────────┐               │
│  ├── full_name                                              │               │
│  ├── email                                                  │               │
│  ├── role ('student' | 'teacher')                          │               │
│  └── is_active                                              │               │
│                                                              │               │
│  course                                                      │               │
│  ├── id (PK)                                                │               │
│  ├── code (UNIQUE)                                          │               │
│  └── name                                                    │               │
│       │                                                      │               │
│       ▼                                                      │               │
│  question_bank                                               │               │
│  ├── id (PK)                                                │               │
│  ├── course_id (FK) ──────────────────────┘                 │               │
│  ├── question_text                                          │               │
│  ├── question_type                                          │               │
│  └── default_points                                          │               │
│       │                                                      │               │
│       ▼                                                      │               │
│  question_option                                             │               │
│  ├── id (PK)                                                │               │
│  ├── question_id (FK)                                       │               │
│  ├── option_text                                            │               │
│  ├── is_correct                                             │               │
│  └── order_index                                            │               │
│                                                              │               │
│  test                                                        │               │
│  ├── id (PK)                                                │               │
│  ├── course_id (FK)                                         │               │
│  ├── title                                                  │               │
│  ├── description                                            │               │
│  └── total_points                                           │               │
│       │                                                      │               │
│       ▼                                                      │               │
│  test_question (junction table)                             │               │
│  ├── test_id (FK)                                           │               │
│  ├── question_id (FK)                                       │               │
│  ├── order_index                                            │               │
│  └── points                                                 │               │
│       │                                                      │               │
│       ▼                                                      │               │
│  test_attempt                                                │               │
│  ├── id (PK)                                                │               │
│  ├── test_id (FK)                                           │               │
│  ├── student_id (FK) ◄──────────────────────────────────────┘               │
│  ├── attempt_number                                                         │
│  ├── status ('in_progress' | 'graded')                                     │
│  ├── score                                                                  │
│  ├── max_score                                                              │
│  ├── percentage                                                             │
│  ├── submitted_at                                                           │
│  └── auto_graded                                                            │
│       │                                                                     │
│       ▼                                                                     │
│  student_answer                                                             │
│  ├── id (PK)                                                               │
│  ├── attempt_id (FK)                                                       │
│  ├── question_id (FK)                                                      │
│  ├── selected_option_id (FK)                                               │
│  ├── is_correct                                                            │
│  ├── score                                                                 │
│  └── graded_at                                                             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Key Users
- **Teacher account**: DNI `09393767` (Ramiro's test account)
- **Sample teacher in seed data**: DNI `12345678A`

---

## API Endpoints

### Health & System
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check (DB connection) |
| GET | `/version` | Returns version from VERSION file |

### Tests
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/available_tests` | List all tests with question count |
| GET | `/tests/{test_id}` | Get test with questions and options |
| POST | `/tests/{test_id}/start?student_dni=XXX` | Start a test attempt |
| PUT | `/tests/{test_id}` | Rename test (teacher only) |
| DELETE | `/tests/{test_id}?teacher_dni=XXX` | Delete test (teacher only) |
| POST | `/tests/random_from_bank` | Create random test from question bank |
| GET | `/tests/{test_id}/results` | Get test results summary |
| GET | `/tests/{test_id}/analytics` | Detailed analytics (questions, podium) |

### Attempts
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/attempts/{attempt_id}/submit` | Submit answers and get score |
| GET | `/student/{dni}/attempts` | Get all attempts for a user |

### Teacher Dashboard
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/teacher/dashboard_overview?teacher_dni=XXX` | Full dashboard data |

---

## Frontend Features

### Portal Page (`portal.html` + `portal.js`)

1. **Identification Section**
   - DNI input field
   - Cookie-based session (7-day expiry)
   - Role detection (student vs teacher)

2. **Welcome Section**
   - Shows user name and role
   - Dashboard button (teacher only)

3. **Take a Test Section**
   - Dropdown with all available tests
   - Start test button
   - View podium button
   - Create random test (specify number of questions)
   - **Test Types**: Quiz, Practice, or Exam (see Test Types section below)

   **Test Types**

   When creating a random test, users can choose between three test types, each with different behaviors:

   | Test Type | Attempts | Time Limit | Purpose |
   |-----------|----------|------------|---------|
   | **Practice** | Unlimited | None | Self-paced learning and practice. No pressure, answers shown immediately after submission. |
   | **Quiz** | 2 attempts (default) | 30 minutes (default) | Regular formative assessment. Moderate time limit, limited retries. |
   | **Exam** | 1 attempt only | 60 minutes (default) | High-stakes summative evaluation. Single attempt with strict time limit. |

   **Test Type Features:**
   - **Attempt Enforcement**: Backend prevents starting new attempts once limit is reached
   - **Time Limit Display**: Visual timer shows remaining time during test (changes color when < 10 min)
   - **Auto-Submit**: Test automatically submits when time expires
   - **Time Limit Enforcement**: Backend rejects submissions exceeding time limit
   - **Retry Feedback**: After submission, shows remaining attempts if available
   - **Custom Overrides**: Users can customize attempts/time when creating test (overrides defaults)

4. **My Attempts Section**
   - Table with Date, Test, Attempt#, Score, %, Status
   - **Pagination**: 5 attempts per page with Prev/Next buttons
   - **Filtering**: Only shows graded attempts with score > 0
   - Line chart showing score progression

5. **Teacher Panel** (hidden for students)
   - Delete test button (with confirmation)
   - Rename test button (prompt for new name)
   - Show analytics button (detailed stats)

6. **Footer Banner**
   - Dynamic version fetched from `/version` endpoint
   - Disclaimer text
   - Fixed at bottom of page

### Quiz Page (`quiz.html` + `quiz.js`)

1. **Question Display**
   - Numbered questions with radio button options
   - Clean, readable layout

2. **Submission**
   - Submit button sends all answers
   - Scoring: +0.5 correct, -1/n incorrect, 0 unanswered
   - Color-coded feedback (green correct, red wrong)

3. **Results**
   - Score display with percentage
   - Detailed per-question breakdown

### Dashboard Page (`dashboard.html` + `dashboard.js`)

1. **KPI Cards**
   - Total Students
   - Total Tests
   - Total Attempts
   - Last 7 Days attempts
   - Average Score

2. **Charts**
   - Attempts over time (line chart)
   - Average score by test (bar chart)

3. **Tables**
   - Hardest questions (top 10 by wrong rate)
   - Test performance summary

### Theme System

- CSS variables in `:root` for light theme
- `body.dark` class overrides for dark theme
- Theme preference stored in `localStorage`
- Toggle button in toolbar

---

## Git Workflow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              GIT WORKFLOW                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  LOCAL                    GITHUB                     SERVER                 │
│  ─────                    ──────                     ──────                 │
│                                                                             │
│  ┌─────────┐   push      ┌─────────┐   Actions     ┌─────────────────┐     │
│  │ develop │ ─────────▶  │ develop │ ───────────▶  │ STAGING         │     │
│  │ branch  │             │ branch  │               │ port 8001       │     │
│  └─────────┘             └─────────┘               └─────────────────┘     │
│       │                       │                                             │
│       │ merge                 │                                             │
│       ▼                       ▼                                             │
│  ┌─────────┐   push      ┌─────────┐   Actions     ┌─────────────────┐     │
│  │  main   │ ─────────▶  │  main   │ ───────────▶  │ PRODUCTION      │     │
│  │ branch  │             │ branch  │               │ port 8000       │     │
│  └─────────┘             └─────────┘               └─────────────────┘     │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                              DAILY WORKFLOW                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. Work on develop branch                                                  │
│     git checkout develop                                                    │
│     # make changes                                                          │
│     git add .                                                               │
│     git commit -m "Description"                                             │
│     git push origin develop                                                 │
│     → Deploys to STAGING automatically                                      │
│                                                                             │
│  2. Test on staging                                                         │
│     http://quiz.ramiro-rego.com:8001                                       │
│                                                                             │
│  3. When ready for production                                               │
│     # Bump version                                                          │
│     # Edit VERSION: 1.0.X-develop → 1.0.Y-production                       │
│     git add VERSION                                                         │
│     git commit -m "Bump version to 1.0.Y-production"                       │
│                                                                             │
│     # Merge to main                                                         │
│     git checkout main                                                       │
│     git merge develop                                                       │
│     git push origin main                                                    │
│     → Deploys to PRODUCTION automatically                                   │
│                                                                             │
│  4. Go back to develop                                                      │
│     git checkout develop                                                    │
│     # Edit VERSION: 1.0.Y-production → 1.0.Y-develop                       │
│     git add VERSION                                                         │
│     git commit -m "Start development on 1.0.Y-develop"                     │
│     git push origin develop                                                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Important Rules
- **NEVER push untested code to `main`** — production must always work
- **Always test in staging first**
- **Bump version before merging to main**

---

## CI/CD Pipeline

### File: `.github/workflows/ci-cd.yml`

```yaml
Triggers:
  - Push to main → Deploy to Production
  - Push to develop → Deploy to Staging

Jobs:
  1. quality
     - Checkout code
     - Setup Python 3.11
     - Install dependencies
     - Run Ruff linting
     - Run Ruff format check
     - Run pytest (if tests exist)

  2. deploy-staging (only on develop)
     - Checkout code
     - Setup SSH
     - rsync files to /home/ramiro_rego/quiz-backend-staging
     - Run deploy_staging.sh
     - Health check on port 8001

  3. deploy-production (only on main)
     - Checkout code
     - Setup SSH
     - rsync files to /home/ramiro_rego/quiz-backend
     - Run deploy.sh
     - Health check via NGINX
```

### File: `.github/workflows/sync-staging-db.yml`

Manual workflow to sync production database to staging:
- Triggered manually from GitHub Actions UI
- Requires typing "sync" to confirm
- Stops staging service
- Drops and recreates staging database
- Copies production data via pg_dump/psql
- Restarts staging service

---

## Version Management

### Version Format
```
MAJOR.STABLE.MINOR-ENVIRONMENT

Examples:
  1.0.0-develop      # First version, development
  1.0.1-production   # First production release
  1.0.2-develop      # After production release, back to dev
  1.1.0-develop      # Stable variant bump
  2.0.0-develop      # Major release bump
```

### When to Bump
| Change | Action |
|--------|--------|
| Push to develop | No change (stays X.Y.Z-develop) |
| Merge to main | MINOR++ and change to production |
| Significant feature set | STABLE++ (you decide when) |
| Breaking changes | MAJOR++ (you decide when) |

### Version Display
- Fetched from `/version` endpoint
- Displayed in footer of all pages
- Shows environment (develop/production)

---

## Common Operations

### View Differences Between Branches
```powershell
git diff main..develop --stat    # Summary
git diff main..develop           # Full diff
```

### Sync Branches
```powershell
# Update develop from main
git checkout develop
git merge main
git push origin develop

# Update main from develop (for production)
git checkout main
git merge develop
git push origin main
```

### Check Git Status
```powershell
git status
git log --oneline --graph --all -10
```

### Database Operations (on server)
```bash
# Sync staging from production
./sync-db-to-staging.sh
# Or via GitHub Actions: "Sync Staging DB from Production"

# Manual database access
sudo -u postgres psql quiz_platform
sudo -u postgres psql quiz_platform_staging

# Useful queries
SELECT * FROM app_user WHERE role = 'teacher';
SELECT * FROM test ORDER BY id DESC LIMIT 5;
SELECT DISTINCT status FROM test_attempt;
```

### Restart Services
```bash
sudo systemctl restart quiz-backend.service
sudo systemctl restart quiz-backend-staging.service
```

---

## Troubleshooting

### Common Issues

| Problem | Solution |
|---------|----------|
| 405 Method Not Allowed | Endpoint doesn't exist in api.py |
| 404 Not Found | Wrong URL or endpoint path |
| venv not found | Run deploy script to create venv |
| Ruff format error | Run `python -m ruff format app/api.py` |
| Push didn't deploy | Check GitHub Actions for errors |
| Database mismatch | Run sync-staging-db workflow |
| Service won't start | Check logs with journalctl |

### Debug Commands
```bash
# Check if app is running
curl http://localhost:8001/health

# Check version
curl http://localhost:8001/version

# View service status
sudo systemctl status quiz-backend-staging.service

# View recent logs
sudo journalctl -u quiz-backend-staging.service -n 100 --no-pager

# Check port listening
ss -tlnp | grep 8001
```

---

## Current State

### Completed Features (as of latest session)
- ✅ Dynamic version footer banner on all pages
- ✅ Filter attempts: only show graded with score > 0
- ✅ `/version` endpoint in api.py
- ✅ Pagination in "My Attempts" (5 per page)
- ✅ Rename test functionality (PUT endpoint)
- ✅ CI/CD for both staging and production
- ✅ Manual database sync workflow

### Current Version
```
1.0.3-develop (staging)
1.0.2-production (production)
```

### Known Working
- All pages load correctly
- Theme toggle works
- Login via DNI works
- Tests can be taken and scored
- Teacher panel functions work
- Analytics display correctly

---

## Continuation Prompt

Copy everything below this line to continue development in a new chat:

---

```
## Quiz Platform - Continue Development

### Quick Context
- **Project**: Cloud Digital Leader Quiz Platform
- **Stack**: FastAPI + Vanilla JS + PostgreSQL
- **Repo**: https://github.com/foreswearer/quiz
- **Local**: c:\projects\quiz
- **Production**: https://quiz.ramiro-rego.com (main branch, port 8000)
- **Staging**: http://quiz.ramiro-rego.com:8001 (develop branch, port 8001)

### Git Workflow
develop → push → staging → test → merge to main → production

### Version Format
MAJOR.STABLE.MINOR-ENVIRONMENT (e.g., 1.0.3-develop)

### Current Version
Check VERSION file for current version.

### Key Files
- app/api.py - All backend endpoints
- static/js/portal.js - Main frontend logic
- static/css/base.css - All styles
- .github/workflows/ci-cd.yml - Deployment pipeline

### Recent Features
- Dynamic version footer
- Pagination (5 per page) in My Attempts
- Rename test functionality
- Database sync workflow

### Key DNIs
- Teacher: 09393767
- Sample teacher: 12345678A

### Common Commands
```powershell
cd c:\projects\quiz
git status
git checkout develop
git add .
git commit -m "message"
git push origin develop
```

### To Deploy to Production
```powershell
# Edit VERSION to X.Y.Z-production
git add VERSION
git commit -m "Bump version to X.Y.Z-production"
git checkout main
git merge develop
git push origin main
git checkout develop
# Edit VERSION to X.Y.Z-develop
git add VERSION
git commit -m "Start development on X.Y.Z-develop"
git push origin develop
```

### What I want to do now:
[DESCRIBE YOUR TASK HERE]
```

---

## Appendix: File Contents Reference

When starting a new chat, you may need to upload these files for context:
1. `app/api.py` - If modifying backend
2. `static/js/portal.js` - If modifying frontend
3. `static/css/base.css` - If modifying styles
4. `.github/workflows/ci-cd.yml` - If modifying deployment
5. `VERSION` - Current version

---

*Last updated: November 2025*
*Maintainer: Ramiro Rego*
