"""
Unit tests for:
  POST /blacklists
  GET  /blacklists/<email>

All database interactions are mocked — no real DB connection is required.
"""
import json
import pytest
from unittest.mock import patch, MagicMock

# Patch target: the module where the names are looked up at call time
BL = "app.resources.blacklist_resource"

VALID_EMAIL = "user@example.com"
VALID_UUID = "123e4567-e89b-12d3-a456-426614174000"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def post_blacklist(client, headers, payload):
    return client.post("/blacklists", data=json.dumps(payload), headers=headers)


def get_blacklist(client, headers, email):
    return client.get(f"/blacklists/{email}", headers=headers)


# ===========================================================================
# POST /blacklists
# ===========================================================================

class TestPostBlacklist:

    # --- Authentication ---

    def test_post_requires_jwt(self, client):
        resp = client.post("/blacklists", data=json.dumps({}), content_type="application/json")
        assert resp.status_code == 401

    def test_post_invalid_token_returns_401(self, client):
        headers = {"Authorization": "Bearer invalid.token.here", "Content-Type": "application/json"}
        resp = post_blacklist(client, headers, {"email": VALID_EMAIL, "app_uuid": VALID_UUID})
        assert resp.status_code == 401

    # --- Successful creation ---

    def test_post_creates_entry_successfully(self, client, auth_headers):
        with patch(f"{BL}.BlacklistEmail.query") as mock_query, \
             patch(f"{BL}.db.session") as mock_session:
            mock_query.filter_by.return_value.first.return_value = None

            resp = post_blacklist(client, auth_headers, {
                "email": VALID_EMAIL, "app_uuid": VALID_UUID, "blocked_reason": "spam"
            })

            assert resp.status_code == 201
            assert VALID_EMAIL in resp.get_json()["message"]
            mock_session.add.assert_called_once()
            mock_session.commit.assert_called_once()

    def test_post_without_blocked_reason_succeeds(self, client, auth_headers):
        with patch(f"{BL}.BlacklistEmail.query") as mock_query, \
             patch(f"{BL}.db.session"):
            mock_query.filter_by.return_value.first.return_value = None
            resp = post_blacklist(client, auth_headers, {"email": VALID_EMAIL, "app_uuid": VALID_UUID})
            assert resp.status_code == 201

    def test_post_with_empty_blocked_reason_treated_as_none(self, client, auth_headers):
        with patch(f"{BL}.BlacklistEmail.query") as mock_query, \
             patch(f"{BL}.db.session"):
            mock_query.filter_by.return_value.first.return_value = None
            resp = post_blacklist(client, auth_headers, {
                "email": VALID_EMAIL, "app_uuid": VALID_UUID, "blocked_reason": "  "
            })
            assert resp.status_code == 201

    # --- Validation errors (no DB call needed) ---

    def test_post_missing_email_returns_400(self, client, auth_headers):
        resp = post_blacklist(client, auth_headers, {"app_uuid": VALID_UUID})
        assert resp.status_code == 400
        assert "email" in resp.get_json()["message"].lower()

    def test_post_invalid_email_format_returns_400(self, client, auth_headers):
        resp = post_blacklist(client, auth_headers, {"email": "not-an-email", "app_uuid": VALID_UUID})
        assert resp.status_code == 400
        assert "email" in resp.get_json()["message"].lower()

    def test_post_missing_app_uuid_returns_400(self, client, auth_headers):
        resp = post_blacklist(client, auth_headers, {"email": VALID_EMAIL})
        assert resp.status_code == 400
        assert "app_uuid" in resp.get_json()["message"].lower()

    def test_post_invalid_app_uuid_returns_400(self, client, auth_headers):
        resp = post_blacklist(client, auth_headers, {"email": VALID_EMAIL, "app_uuid": "not-a-uuid"})
        assert resp.status_code == 400
        assert "uuid" in resp.get_json()["message"].lower()

    def test_post_blocked_reason_exceeding_255_chars_returns_400(self, client, auth_headers):
        resp = post_blacklist(client, auth_headers, {
            "email": VALID_EMAIL, "app_uuid": VALID_UUID, "blocked_reason": "x" * 256
        })
        assert resp.status_code == 400
        assert "255" in resp.get_json()["message"]

    def test_post_non_string_blocked_reason_returns_400(self, client, auth_headers):
        resp = post_blacklist(client, auth_headers, {
            "email": VALID_EMAIL, "app_uuid": VALID_UUID, "blocked_reason": 12345
        })
        assert resp.status_code == 400

    def test_post_non_json_body_returns_400(self, client, auth_headers):
        headers = {**auth_headers, "Content-Type": "text/plain"}
        resp = client.post("/blacklists", data="plain text", headers=headers)
        assert resp.status_code == 400

    # --- Conflict ---

    def test_post_duplicate_email_returns_409(self, client, auth_headers):
        with patch(f"{BL}.BlacklistEmail.query") as mock_query:
            mock_query.filter_by.return_value.first.return_value = MagicMock()  # already exists

            resp = post_blacklist(client, auth_headers, {"email": VALID_EMAIL, "app_uuid": VALID_UUID})

            assert resp.status_code == 409
            assert VALID_EMAIL in resp.get_json()["message"]


# ===========================================================================
# GET /blacklists/<email>
# ===========================================================================

class TestGetBlacklist:

    # --- Authentication ---

    def test_get_requires_jwt(self, client):
        resp = client.get(f"/blacklists/{VALID_EMAIL}")
        assert resp.status_code == 401

    def test_get_invalid_token_returns_401(self, client):
        resp = get_blacklist(client, {"Authorization": "Bearer bad.token"}, VALID_EMAIL)
        assert resp.status_code == 401

    # --- Email not in blacklist ---

    def test_get_returns_not_blacklisted_for_unknown_email(self, client, auth_headers):
        with patch(f"{BL}.BlacklistEmail.query") as mock_query:
            mock_query.filter_by.return_value.first.return_value = None

            resp = get_blacklist(client, auth_headers, VALID_EMAIL)

            assert resp.status_code == 200
            data = resp.get_json()
            assert data["is_blacklisted"] is False
            assert data["blocked_reason"] is None

    # --- Email in blacklist ---

    def test_get_returns_blacklisted_email_with_reason(self, client, auth_headers):
        with patch(f"{BL}.BlacklistEmail.query") as mock_query:
            entry = MagicMock()
            entry.blocked_reason = "phishing"
            mock_query.filter_by.return_value.first.return_value = entry

            resp = get_blacklist(client, auth_headers, VALID_EMAIL)

            assert resp.status_code == 200
            data = resp.get_json()
            assert data["is_blacklisted"] is True
            assert data["blocked_reason"] == "phishing"

    def test_get_returns_blacklisted_email_without_reason(self, client, auth_headers):
        with patch(f"{BL}.BlacklistEmail.query") as mock_query:
            entry = MagicMock()
            entry.blocked_reason = None
            mock_query.filter_by.return_value.first.return_value = entry

            resp = get_blacklist(client, auth_headers, VALID_EMAIL)

            assert resp.status_code == 200
            data = resp.get_json()
            assert data["is_blacklisted"] is True
            assert data["blocked_reason"] is None

    # --- Validation ---

    def test_get_invalid_email_format_returns_400(self, client, auth_headers):
        resp = get_blacklist(client, auth_headers, "not-an-email")
        assert resp.status_code == 400
        assert "email" in resp.get_json()["message"].lower()
