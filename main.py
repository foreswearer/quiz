from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

from app.ui import router as ui_router
from app.api import router as api_router

app = FastAPI()

# UI (HTML) routes
app.include_router(ui_router)

# JSON API routes: /available_tests, /student/{dni}/attempts, /tests/...
app.include_router(api_router)

# Static files for CSS/JS
app.mount("/static", StaticFiles(directory="static"), name="static")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
    )
