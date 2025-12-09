from fastapi import APIRouter

router = APIRouter()


@router.get("/health")
def health():
    from ..db import check_db

    try:
        check_db()
        return {"status": "ok", "db": "ok"}
    except Exception as e:
        return {"status": "error", "db": str(e)}


@router.get("/version")
def version():
    """Return the application version from VERSION file."""
    try:
        with open("VERSION", "r") as f:
            ver = f.read().strip()
        return {"version": ver}
    except FileNotFoundError:
        return {"version": "unknown"}
