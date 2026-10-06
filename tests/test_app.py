import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.app import app


def test_home():
    client = app.test_client()
    response = client.get("/")
    assert response.status_code == 200
    assert response.get_json()["message"] == "OrderHub API"


def test_health():
    client = app.test_client()
    response = client.get("/health")
    assert response.status_code == 200
    assert response.get_json()["status"] == "UP"


def test_orders():
    client = app.test_client()
    response = client.get("/orders")
    assert response.status_code == 200
    assert len(response.get_json()) > 0


def test_version():
    client = app.test_client()
    response = client.get("/version")

    assert response.status_code == 200

    data = response.get_json()

    assert data["version"] == "1.0.0"
    assert "build" in data
    assert "commit" in data