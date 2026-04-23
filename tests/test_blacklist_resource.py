"""
Unit tests for:
  POST /blacklists
  GET  /blacklists/<email>
"""
import json
import pytest


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

VALID_EMAIL = "user@example.com"
VALID_UUID = "123e4567-e89b-12d3-a456-426614174000"


def post_blacklist(client, headers, payload):
    return client.post(
        "/blacklists",
        data=json.dumps(payload),
        headers=headers,
    )


def get_blacklist(client, headers, email):
    return client.get(f"/blacklists/{email}", headers=headers)


# ===========================================================================
# POST /blacklists
# ===========================================================================

class TestPostBlacklist:

    # --- Authentication ---

    def test_post_requires_jwt(self, client):
        """Request without token must return 401."""
        resp = client.post("/blacklists", data=json.dumps({}), content_type="application/json")
        assert resp.status_code == 401

    def test_post_invalid_token_returns_401(self, client):
        """Request with a malformed token must return 401."""
        headers = {"Authorization": "Bearer invalid.token.here", "Content-Type": "application/json"}
        resp = post_blacklist(client, headers, {"email": VALID_EMAIL, "app_uuid": VALID_UUID})
        assert resp.status_code == 401

    # --- Successful creation ---

    def test_post_creates_entry_successfully(self, client, auth_headers):
        """Valid payload must create the entry and return 201."""
        payload = {"email": VALID_EMAIL, "app_uuid": VALID_UUID, "blocked_reason": "spam"}
        resp = post_blacklist(client, auth_headers, payload)
        assert resp.status_code == 201
        data = resp.get_json()
        assert VALID_EMAIL in data["message"]

    def test_post_without_blocked_reason_succeeds(self, client, auth_headers):
        """blocked_reason is optional; omitting it must still return 201."""
        payload = {"email": VALID_EMAIL, "app_uuid": VALID_UUID}
        resp = post_blacklist(client, auth_headers, payload)
        assert resp.status_code == 201

    def test_post_with_empty_blocked_reason_treated_as_none(self, client, auth_headers):
        """An empty blocked_reason string should be stored as None."""
        payload = {"email": VALID_EMAIL, "app_uuid": VALID_UUID, "blocked_reason": "  "}
        resp = post_blacklist(client, auth_headers, payload)
        assert resp.status_code == 201

    # --- Validation errors ---

    def test_post_missing_email_returns_400(self, client, auth_headers):
        payload = {"app_uuid": VALID_UUID}
        resp = post_blacklist(client, auth_headers, payload)
        assert resp.status_code == 400
        assert "email" in resp.get_json()["message"].lower()

    def test_post_invalid_email_format_returns_400(self, client, auth_headers):
        payload = {"email": "not-an-email", "app_uuid": VALID_UUID}
        resp = post_blacklist(client, auth_headers, payload)
        assert resp.status_code == 400
        assert "email" in resp.get_json()["message"].lower()

    def test_post_missing_app_uuid_returns_400(self, client, auth_headers):
        payload = {"email": VALID_EMAIL}
        resp = post_blacklist(client, auth_headers, payload)
        assert resp.status_code == 400
        assert "app_uuid" in resp.get_json()["message"].lower()

    def test_post_invalid_app_uuid_returns_400(self, client, auth_headers):
        payload = {"email": VALID_EMAIL, "app_uuid": "not-a-uuid"}
        resp = post_blacklist(client, auth_headers, payload)
        assert resp.status_code == 400
        assert "uuid" in resp.get_json()["message"].lower()

    def test_post_blocked_reason_exceeding_255_chars_returns_400(self, client, auth_headers):
        payload = {"email": VALID_EMAIL, "app_uuid": VALID_UUID, "blocked_reason": "x" * 256}
        resp = post_blacklist(client, auth_headers, payload)
        assert resp.status_code == 400
        assert "255" in resp.get_json()["message"]

    def test_post_non_string_blocked_reason_returns_400(self, client, auth_headers):
        payload = {"email": VALID_EMAIL, "app_uuid": VALID_UUID, "blocked_reason": 12345}
        resp = post_blacklist(client, auth_headers, payload)
        assert resp.status_code == 400

    def test_post_non_json_body_returns_400(self, client, auth_headers):
        headers = {k: v for k, v in auth_headers.items()}
        headers["Content-Type"] = "text/plain"
        resp = client.post("/blacklists", data="plain text", headers=headers)
        assert resp.status_code == 400

    # --- Conflict ---

    def test_post_duplicate_email_returns_409(self, client, auth_headers):
        """Adding the same email twice must return 409 on the second attempt."""
        payload = {"email": VALID_EMAIL, "app_uuid": VALID_UUID}
        post_blacklist(client, auth_headers, payload)
        resp = post_blacklist(client, auth_headers, payload)
        assert resp.status_code == 409
        assert VALID_EMAIL in resp.get_json()["message"]


# ===========================================================================
# GET /blacklists/<email>
# ===========================================================================

class TestGetBlacklist:

    # --- Authentication ---

    def test_get_requires_jwt(self, client):
        """Request without token must return 401."""
        resp = client.get(f"/blacklists/{VALID_EMAIL}")
        assert resp.status_code == 401

    def test_get_invalid_token_returns_401(self, client):
        headers = {"Authorization": "Bearer bad.token"}
        resp = get_blacklist(client, headers, VALID_EMAIL)
        assert resp.status_code == 401

    # --- Email not in blacklist ---

    def test_get_returns_not_blacklisted_for_unknown_email(self, client, auth_headers):
        """An email not in the DB must return is_blacklisted=False."""
        resp = get_blacklist(client, auth_headers, "unknown@example.com")
        assert resp.status_code == 200
        data = resp.get_json()
        assert data["is_blacklisted"] is False
        assert data["blocked_reason"] is None

    # --- Email in blacklist ---

    def test_get_returns_blacklisted_for_existing_email(self, client, auth_headers):
        """An email that was added must return is_blacklisted=True."""
        payload = {"email": VALID_EMAIL, "app_uuid": VALID_UUID, "blocked_reason": "phishing"}
        post_blacklist(client, auth_headers, payload)

        resp = get_blacklist(client, auth_headers, VALID_EMAIL)
        assert resp.status_code == 200
        data = resp.get_json()
        assert data["is_blacklisted"] is True
        assert data["blocked_reason"] == "phishing"

    def test_get_blacklisted_email_without_reason(self, client, auth_headers):
        """is_blacklisted=True and blocked_reason=None when none was provided."""
        payload = {"email": VALID_EMAIL, "app_uuid": VALID_UUID}
        post_blacklist(client, auth_headers, payload)

        resp = get_blacklist(client, auth_headers, VALID_EMAIL)
        assert resp.status_code == 200
        data = resp.get_json()
        assert data["is_blacklisted"] is True
        assert data["blocked_reason"] is None

    # --- Validation ---

    def test_get_invalid_email_format_returns_400(self, client, auth_headers):
        """A malformed email in the URL path must return 400."""
        resp = get_blacklist(client, auth_headers, "not-an-email")
        assert resp.status_code == 400
        assert "email" in resp.get_json()["message"].lower()
