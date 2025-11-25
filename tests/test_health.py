# tests/test_health.py

from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.api import router


# Build a minimal app for testing using the real router
test_app = FastAPI()
test_app.include_router(router)

client = TestClient(test_app)


def test_health_ok():
    response = client.get("/health")
    assert response.status_code == 200
    # Optional: we don't care if db is ok or not for CI,
    # only that the endpoint exists and responds.
    assert "status" in response.json()
