import os
import pytest
from flask_jwt_extended import create_access_token

# Force SQLite before any app module is imported — this ensures Config picks it up
# at class-definition time and Flask-SQLAlchemy never loads the psycopg2 driver.
os.environ["DATABASE_URL"] = "sqlite:///:memory:"
os.environ["JWT_SECRET_KEY"] = "test-secret-key"
os.environ["SERVICE_USERNAME"] = "testuser"
os.environ["SERVICE_PASSWORD"] = "testpassword"

from app import create_app, db as _db  # noqa: E402  (import after env setup)


@pytest.fixture(scope="session")
def app():
    """Create application with in-memory SQLite for the whole test session."""
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
        _db.create_all()
        yield flask_app
        _db.drop_all()


@pytest.fixture
def client(app):
    """Flask test client."""
    return app.test_client()


@pytest.fixture(autouse=True)
def clean_db(app):
    """Roll back every test so they are isolated."""
    with app.app_context():
        yield
        _db.session.rollback()
        for table in reversed(_db.metadata.sorted_tables):
            _db.session.execute(table.delete())
        _db.session.commit()


@pytest.fixture
def auth_headers(app):
    """Return Authorization header with a valid JWT."""
    with app.app_context():
        token = create_access_token(identity="testuser")
    return {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
