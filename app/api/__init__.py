"""
API module - combines all route handlers.

Structure:
- health.py    : /health, /version
- tests.py     : /available_tests, /tests/{id}, create/rename/delete tests
- attempts.py  : /tests/{id}/start, /attempts/{id}/submit, /student/{dni}/attempts
- analytics.py : /tests/{id}/results, /tests/{id}/analytics, /teacher/dashboard_overview
- questions.py : /courses, /api/question-bank/*
"""

from fastapi import APIRouter

from .health import router as health_router
from .tests import router as tests_router
from .attempts import router as attempts_router
from .analytics import router as analytics_router
from .questions import router as questions_router

router = APIRouter()

# Include all sub-routers
router.include_router(health_router)
router.include_router(tests_router)
router.include_router(attempts_router)
router.include_router(analytics_router)
router.include_router(questions_router)
