# Quiz Platform: Exhaustive Technical Documentation

## 1. System Overview

### 1.1 Introduction
The Quiz Platform is a web-based application designed to facilitate the creation, administration, and analysis of quizzes for the "Cloud Digital Leader" course. It supports two distinct user roles: **Students**, who take tests and view their own results, and **Teachers**, who manage tests and view comprehensive analytics.

The system is architected to support **Continuous Deployment** with two parallel environments:
1.  **Production**: The stable environment used by end-users.
2.  **Staging**: An experimental environment for testing new features.

### 1.2 Technology Stack
*   **Backend Framework**: FastAPI (Python 3.11)
*   **Database**: PostgreSQL 14+
*   **Database Driver**: `psycopg2` (Synchronous)
*   **Frontend**: HTML5, CSS3, Vanilla JavaScript (ES6+)
*   **Web Server**: Nginx (Reverse Proxy)
*   **Application Server**: Uvicorn (ASGI)
*   **Process Management**: Systemd
*   **CI/CD**: GitHub Actions
*   **Hosting**: Linux VPS (Ubuntu/Debian)

### 1.3 Directory Structure
```
/
├── .github/workflows/   # CI/CD definitions
│   └── ci-cd.yml        # Main pipeline
├── app/                 # Backend Application Code
│   ├── __init__.py
│   ├── api.py           # REST API Endpoints & Logic
│   ├── config.py        # Configuration & Env Vars
│   ├── db.py            # Database Connection Pooling
│   ├── schemas.py       # Pydantic Models (Request/Response)
│   └── ui.py            # HTML Template Rendering Routes
├── static/              # Static Assets
│   ├── css/             # Stylesheets (base.css, portal.css)
│   └── js/              # Frontend Logic (portal.js, dashboard.js)
├── templates/           # Jinja2 HTML Templates
│   ├── index.html       # Landing Page
│   ├── portal.html      # Main Student/Teacher Portal
│   └── quiz.html        # Test Taking Interface
├── deploy.sh            # Production Deployment Script
├── deploy_staging.sh    # Staging Deployment Script
├── main.py              # Application Entry Point
├── requirements.txt     # Python Dependencies
└── quiz_backend.sh      # Local Dev Helper Script
```

---

## 2. Database Schema (PostgreSQL)

The database is normalized to 3NF. All IDs are auto-incrementing integers (`SERIAL`).

### 2.1 `app_user`
Stores all users. Authentication is implicit via the `dni` field.
*   `id` (PK): Integer
*   `dni`: Varchar (Unique). The user's login identifier.
*   `full_name`: Varchar. Display name.
*   `email`: Varchar.
*   `role`: Varchar. Enum-like: `'student'` or `'teacher'`.

### 2.2 `course`
Represents a subject area.
*   `id` (PK): Integer
*   `code`: Varchar (e.g., `'2526-45810-A'`).
*   `name`: Varchar.

### 2.3 `question_bank`
The repository of all available questions.
*   `id` (PK): Integer
*   `course_id` (FK -> `course.id`): The subject this question belongs to.
*   `question_text`: Text. The actual question content.
*   `question_type`: Varchar (e.g., `'multiple_choice'`).
*   `default_points`: Float. Usually `0.5`.

### 2.4 `question_option`
The multiple-choice answers for each question.
*   `id` (PK): Integer
*   `question_id` (FK -> `question_bank.id`): Parent question.
*   `option_text`: Text. The answer text.
*   `is_correct`: Boolean. True if this is the correct answer.
*   `order_index`: Integer. Sorting order for display.

### 2.5 `test`
A specific quiz instance (e.g., "Midterm Exam" or a generated random test).
*   `id` (PK): Integer
*   `course_id` (FK -> `course.id`).
*   `title`: Varchar.
*   `description`: Text.
*   `total_points`: Float. Sum of points of all linked questions.

### 2.6 `test_question`
Many-to-Many link between `test` and `question_bank`.
*   `test_id` (FK -> `test.id`).
*   `question_id` (FK -> `question_bank.id`).
*   `order_index`: Integer. Order of the question in this specific test.
*   `points`: Float. Points assigned for this question in this test.

### 2.7 `test_attempt`
A single session of a student taking a test.
*   `id` (PK): Integer
*   `test_id` (FK -> `test.id`).
*   `student_id` (FK -> `app_user.id`).
*   `attempt_number`: Integer. Incremental counter per student/test.
*   `status`: Varchar. `'in_progress'` or `'graded'`.
*   `score`: Float. Final score achieved.
*   `max_score`: Float. Maximum possible score.
*   `percentage`: Float. `(score / max_score) * 100`.
*   `submitted_at`: Timestamp. When the test was finished.
*   `auto_graded`: Boolean.

### 2.8 `student_answer`
Records the specific option chosen by a student.
*   `attempt_id` (FK -> `test_attempt.id`).
*   `question_id` (FK -> `question_bank.id`).
*   `selected_option_id` (FK -> `question_option.id`).
*   `is_correct`: Boolean. Cached validity of the answer.
*   `score`: Float. Points awarded (positive) or deducted (negative).

---

## 3. Application Logic & API Reference

The backend is built with **FastAPI**. All endpoints return JSON.

### 3.1 Public Endpoints

#### `GET /health`
*   **Purpose**: Health check for monitoring tools.
*   **Logic**: Attempts a `SELECT 1` query to the DB.
*   **Response**: `{"status": "ok", "db": "ok"}`.

#### `GET /available_tests`
*   **Purpose**: Lists all tests for the dashboard.
*   **Response**: List of test objects (id, title, description, total_points, num_questions).

### 3.2 Test Taking Flow

#### `POST /tests/{test_id}/start`
*   **Query Param**: `student_dni` (Required).
*   **Logic**:
    1.  Validates DNI exists in `app_user`.
    2.  Calculates next `attempt_number`.
    3.  Creates `test_attempt` with status `'in_progress'`.
    4.  Fetches all questions and options for the test (hiding `is_correct` flag).
*   **Response**: Full test payload including `attempt_id` and questions.

#### `POST /attempts/{attempt_id}/submit`
*   **Body**: `{"answers": [{"question_id": 1, "selected_option_id": 5}, ...]}`
*   **Logic**:
    1.  Validates attempt is `'in_progress'`.
    2.  Iterates through answers:
        *   **Correct**: +0.5 points.
        *   **Incorrect**: -1.0 / (number of options). Penalizes guessing.
        *   **Unanswered**: 0 points.
    3.  Updates `student_answer` table.
    4.  Updates `test_attempt` with final score and status `'graded'`.
*   **Response**: Detailed results including correct answers and score breakdown.

### 3.3 Analytics & Reporting

#### `GET /tests/{test_id}/results`
*   **Purpose**: General summary for students.
*   **Response**:
    *   `summary`: Avg/Min/Max percentage across all students.
    *   `results`: List of best attempts per student.

#### `GET /tests/{test_id}/analytics`
*   **Purpose**: Detailed analytics (Podium, Hardest Questions).
*   **Logic**: Complex SQL aggregations to calculate wrong/correct rates per question and option.
*   **Response**:
    *   `most_failed_question`: Question with highest wrong count.
    *   `most_correct_question`: Question with highest correct count.
    *   `podium_best_single`: Top 3 students by single attempt score.
    *   `podium_best_average`: Top 3 students by average score.

#### `GET /student/{dni}/attempts`
*   **Purpose**: Personal history for a student.
*   **Response**: List of all attempts with scores and dates.

### 3.4 Teacher Features

#### `GET /teacher/dashboard_overview`
*   **Query Param**: `teacher_dni`.
*   **Logic**: Enforces `role == 'teacher'`.
*   **Response**: Global KPIs (total students, tests, attempts), daily activity chart data, and top 10 hardest questions globally.

#### `DELETE /tests/{test_id}`
*   **Query Param**: `teacher_dni`.
*   **Logic**:
    1.  Enforces `role == 'teacher'`.
    2.  **Cascading Delete**: Manually deletes related records in safe order: `student_answer` -> `test_attempt` -> `test_question` -> `test`.
*   **Response**: Confirmation of deleted counts.

#### `POST /tests/random_from_bank`
*   **Body**: `{"student_dni": "...", "num_questions": 20, "course_code": "..."}`
*   **Logic**:
    1.  Creates a new `test` entry.
    2.  Selects `N` random questions from `question_bank` using `ORDER BY random()`.
    3.  Inserts into `test_question`.
*   **Response**: The new `test_id`.

---

## 4. Frontend Architecture

The frontend is a Single Page Application (SPA) feel, implemented with multi-page navigation but heavy JavaScript interactivity on `portal.html`.

### 4.1 Files
*   `portal.html`: The main interface. Contains sections for Login, Dashboard, Test Selection, and Teacher Panel.
*   `portal.js`: Handles all logic for `portal.html`.
    *   **State**: Manages `currentDni` and `currentRole`.
    *   **Cookies**: Stores `quiz_dni` for 7 days to persist login.
    *   **Theme**: Toggles `.dark` class on `<body>` and saves to localStorage.
    *   **API Calls**: Uses `fetch()` with `async/await` for all backend interactions.
    *   **Charts**: Uses `Chart.js` to render the "Attempts over Time" graph.

### 4.2 User Flow
1.  **Login**: User enters DNI. `loadDashboard()` fetches user data.
2.  **Role Detection**:
    *   If `fetch('/teacher/dashboard_overview')` succeeds, role is **Teacher**.
    *   Otherwise, role is **Student**.
3.  **Dashboard Rendering**:
    *   **Student**: Sees "Take a test", "My attempts", "Create random test".
    *   **Teacher**: Sees all Student sections PLUS "Teacher Tools" (Delete Test, Deep Analytics).

---

## 5. CI/CD Pipeline (GitHub Actions)

The pipeline is defined in `.github/workflows/ci-cd.yml`.

### 5.1 Triggers
*   **Push to `main`**: Deploys to Production.
*   **Push to `develop`**: Deploys to Staging.
*   **Pull Request**: Runs Quality Checks only.
*   **Manual (`workflow_dispatch`)**: Allows manual deployment of any branch.

### 5.2 Job: `quality`
Runs on every trigger.
1.  **Checkout Code**.
2.  **Setup Python 3.11**.
3.  **Install Dependencies**: `pip install ruff pytest httpx`.
4.  **Linting**: `ruff check .` (Static analysis).
5.  **Formatting**: `ruff format --check .` (Style enforcement).
6.  **Testing**: `pytest` (Unit tests).

### 5.3 Job: `deploy-production`
Runs only on `main` branch push.
1.  **SSH Setup**: Configures private key from GitHub Secrets.
2.  **Rsync**: Synchronizes files to `/home/ramiro_rego/quiz-backend`.
    *   Excludes: `.git`, `venv`, `__pycache__`.
3.  **Remote Script**: Executes `./deploy.sh`.
4.  **Verification**: Checks `systemctl status quiz-backend.service` and curls `localhost:8000`.

### 5.4 Job: `deploy-staging`
Runs only on `develop` branch push.
1.  **SSH Setup**: Same as production.
2.  **Rsync**: Synchronizes files to `/home/ramiro_rego/quiz-backend-staging`.
3.  **Remote Script**: Executes `./deploy_staging.sh`.
4.  **Verification**: Checks `systemctl status quiz-backend-staging.service`.

---

## 6. Deployment Scripts

### 6.1 `deploy.sh` (Production)
1.  **Variables**: Sets paths for `APP_DIR`, `VENV_DIR`, and `SERVICE_FILE`.
2.  **Virtualenv**: Creates `venv` if missing.
3.  **Install**: `pip install -r requirements.txt`.
4.  **Systemd**: Writes `/etc/systemd/system/quiz-backend.service`.
    *   **Environment**: Sets `QUIZ_DB_NAME=quiz_platform`.
    *   **Port**: `8000`.
5.  **Restart**: `systemctl restart quiz-backend.service`.

### 6.2 `deploy_staging.sh` (Staging)
1.  **Variables**: Targets `quiz-backend-staging` directory.
2.  **Database Automation**:
    *   Checks if `quiz_platform_staging` exists using `psql`.
    *   If not, runs `createdb -O quiz_user quiz_platform_staging`.
3.  **Systemd**: Writes `/etc/systemd/system/quiz-backend-staging.service`.
    *   **Environment**: Sets `QUIZ_DB_NAME=quiz_platform_staging`.
    *   **Port**: `8001`.
4.  **Restart**: `systemctl restart quiz-backend-staging.service`.
