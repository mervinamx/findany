import pytest

from app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True

    with app.test_client() as test_client:
        yield test_client


def test_health_endpoint(client):
    response = client.get("/api/health")

    assert response.status_code == 200
    assert response.get_json() == {"status": "ok", "app": "FindAny"}


def test_stats_endpoint(client):
    response = client.get("/api/stats")

    assert response.status_code == 200
    data = response.get_json()
    assert "total_phones" in data
    assert "total_brands" in data
    assert "db_engine" in data


def test_cors_header_present(client):
    response = client.get("/api/health")

    assert response.headers.get("Access-Control-Allow-Origin") == "*"


def test_main_api_endpoints_exist(client):
    phones_response = client.get("/api/phones")
    brands_response = client.get("/api/brands")

    assert phones_response.status_code == 200
    assert brands_response.status_code == 200
