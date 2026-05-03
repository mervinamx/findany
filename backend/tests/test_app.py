import pytest
from app import app


@pytest.fixture
def client():
    """Test client fixture."""
    app.config['TESTING'] = True
    # Use a test database or mock the database for unit tests
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'

    with app.test_client() as client:
        yield client


def test_health_endpoint(client):
    """Test the health endpoint."""
    response = client.get('/api/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'ok'
    assert data['app'] == 'FindAny'


def test_home_endpoint(client):
    """Test the home endpoint."""
    response = client.get('/')
    assert response.status_code == 200


def test_cors_headers(client):
    """Test CORS headers are present."""
    response = client.get('/api/health')
    assert 'Access-Control-Allow-Origin' in response.headers
    assert 'Access-Control-Allow-Methods' in response.headers
    assert 'Access-Control-Allow-Headers' in response.headers


def test_api_endpoints_exist(client):
    """Test that main API endpoints exist (may return errors due to DB, but should not 404)."""
    # These endpoints should exist even if DB is not available
    response = client.get('/api/phones')
    # Should not be 404, even if DB error
    assert response.status_code != 404

    response = client.get('/api/brands')
    assert response.status_code != 404