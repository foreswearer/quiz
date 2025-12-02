import os

from fastapi import APIRouter
from fastapi.responses import FileResponse

router = APIRouter()

BASE_DIR = os.path.dirname(os.path.dirname(__file__))
TEMPLATES_DIR = os.path.join(BASE_DIR, "templates")


@router.get("/", include_in_schema=False)
def portal():
    return FileResponse(os.path.join(TEMPLATES_DIR, "portal.html"))


@router.get("/quiz", include_in_schema=False)
def quiz_page():
    return FileResponse(os.path.join(TEMPLATES_DIR, "quiz.html"))


@router.get("/dashboard", include_in_schema=False)
def dashboard_page():
    return FileResponse(os.path.join(TEMPLATES_DIR, "dashboard.html"))
