from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

from app.api import router as api_router
from app.ui import router as ui_router

app = FastAPI(title="Cloud Digital Leader Quiz Backend")

app.include_router(api_router)
app.include_router(ui_router)

app.mount("/static", StaticFiles(directory="static"), name="static")
