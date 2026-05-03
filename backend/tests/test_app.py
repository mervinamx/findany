import pytest
from app import app, db


@pytest.fixture
def client():
    """Test client fixture."""
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'

    with app.test_client() as client:
        with app.app_context():
            db.create_all()
        yield client


def test_health_endpoint(client):
    """Test the health endpoint."""
    response = client.get('/api/health')
    assert response.status_code == 200
    assert b'healthy' in response.data


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


def test_database_connection(client):
    """Test database connection."""
    with app.app_context():
        # Test basic database operations
        from sqlalchemy import text
        result = db.session.execute(text('SELECT 1'))
        assert result.fetchone()[0] == 1