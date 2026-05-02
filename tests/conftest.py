import os
import pytest
from flask_jwt_extended import create_access_token

# SQLite URI must be set before any app module is imported so that
# Flask-SQLAlchemy uses the built-in SQLite driver (no psycopg2 needed).
os.environ["DATABASE_URL"] = "sqlite:///:memory:"
os.environ["JWT_SECRET_KEY"] = "test-secret-key"
os.environ["SERVICE_USERNAME"] = "testuser"
os.environ["SERVICE_PASSWORD"] = "testpassword"

from app import create_app  # noqa: E402


@pytest.fixture(scope="session")
def app():
    """Application fixture — DB calls are fully mocked in each test."""
    flask_app = create_app()
    flask_app.config.update(
        TESTING=True,
        SQLALCHEMY_DATABASE_URI="sqlite:///:memory:",
        JWT_SECRET_KEY="test-secret-key",
        SERVICE_USERNAME="testuser",
        SERVICE_PASSWORD="testpassword",
        PROPAGATE_EXCEPTIONS=True,
    )
    with flask_app.app_context():
        yield flask_app


@pytest.fixture
def client(app):
    return app.test_client()


@pytest.fixture
def auth_headers(app):
    """Valid JWT Authorization header."""
    with app.app_context():
        token = create_access_token(identity="testuser")
    return {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
