import json
import uuid


VALID_UUID = str(uuid.uuid4())
VALID_EMAIL = 'test@example.com'


def _auth_header(token):
    return {'Authorization': f'Bearer {token}'}


# ---------------------------------------------------------------------------
# POST /blacklists
# ---------------------------------------------------------------------------

def test_add_email_success(client, auth_token):
    response = client.post(
        '/blacklists',
        data=json.dumps({'email': VALID_EMAIL, 'app_uuid': VALID_UUID}),
        content_type='application/json',
        headers=_auth_header(auth_token),
    )
    assert response.status_code == 201
    data = json.loads(response.data)
    assert VALID_EMAIL in data['message']


def test_add_email_with_blocked_reason(client, auth_token):
    response = client.post(
        '/blacklists',
        data=json.dumps({
            'email': VALID_EMAIL,
            'app_uuid': VALID_UUID,
            'blocked_reason': 'spam',
        }),
        content_type='application/json',
        headers=_auth_header(auth_token),
    )
    assert response.status_code == 201


def test_add_duplicate_email(client, auth_token):
    payload = json.dumps({'email': VALID_EMAIL, 'app_uuid': VALID_UUID})
    client.post(
        '/blacklists',
        data=payload,
        content_type='application/json',
        headers=_auth_header(auth_token),
    )
    response = client.post(
        '/blacklists',
        data=payload,
        content_type='application/json',
        headers=_auth_header(auth_token),
    )
    assert response.status_code == 409


def test_add_email_without_auth(client):
    response = client.post(
        '/blacklists',
        data=json.dumps({'email': VALID_EMAIL, 'app_uuid': VALID_UUID}),
        content_type='application/json',
    )
    assert response.status_code == 401


def test_add_email_invalid_email_format(client, auth_token):
    response = client.post(
        '/blacklists',
        data=json.dumps({'email': 'not-an-email', 'app_uuid': VALID_UUID}),
        content_type='application/json',
        headers=_auth_header(auth_token),
    )
    assert response.status_code == 400


def test_add_email_missing_email(client, auth_token):
    response = client.post(
        '/blacklists',
        data=json.dumps({'app_uuid': VALID_UUID}),
        content_type='application/json',
        headers=_auth_header(auth_token),
    )
    assert response.status_code == 400


def test_add_email_missing_uuid(client, auth_token):
    response = client.post(
        '/blacklists',
        data=json.dumps({'email': VALID_EMAIL}),
        content_type='application/json',
        headers=_auth_header(auth_token),
    )
    assert response.status_code == 400


def test_add_email_invalid_uuid(client, auth_token):
    response = client.post(
        '/blacklists',
        data=json.dumps({'email': VALID_EMAIL, 'app_uuid': 'not-a-uuid'}),
        content_type='application/json',
        headers=_auth_header(auth_token),
    )
    assert response.status_code == 400


def test_add_email_non_json_body(client, auth_token):
    response = client.post(
        '/blacklists',
        data='plain text',
        content_type='text/plain',
        headers=_auth_header(auth_token),
    )
    assert response.status_code == 400


def test_add_email_blocked_reason_too_long(client, auth_token):
    response = client.post(
        '/blacklists',
        data=json.dumps({
            'email': VALID_EMAIL,
            'app_uuid': VALID_UUID,
            'blocked_reason': 'x' * 256,
        }),
        content_type='application/json',
        headers=_auth_header(auth_token),
    )
    assert response.status_code == 400


# ---------------------------------------------------------------------------
# GET /blacklists/<email>
# ---------------------------------------------------------------------------

def test_query_blacklisted_email(client, auth_token):
    client.post(
        '/blacklists',
        data=json.dumps({'email': VALID_EMAIL, 'app_uuid': VALID_UUID}),
        content_type='application/json',
        headers=_auth_header(auth_token),
    )
    response = client.get(
        f'/blacklists/{VALID_EMAIL}',
        headers=_auth_header(auth_token),
    )
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['is_blacklisted'] is True


def test_query_non_blacklisted_email(client, auth_token):
    response = client.get(
        '/blacklists/notlisted@example.com',
        headers=_auth_header(auth_token),
    )
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['is_blacklisted'] is False
    assert data['blocked_reason'] is None


def test_query_email_without_auth(client):
    response = client.get(f'/blacklists/{VALID_EMAIL}')
    assert response.status_code == 401


def test_query_invalid_email_format(client, auth_token):
    response = client.get(
        '/blacklists/not-an-email',
        headers=_auth_header(auth_token),
    )
    assert response.status_code == 400


def test_query_blacklisted_email_returns_blocked_reason(client, auth_token):
    reason = 'spam activity'
    client.post(
        '/blacklists',
        data=json.dumps({
            'email': VALID_EMAIL,
            'app_uuid': VALID_UUID,
            'blocked_reason': reason,
        }),
        content_type='application/json',
        headers=_auth_header(auth_token),
    )
    response = client.get(
        f'/blacklists/{VALID_EMAIL}',
        headers=_auth_header(auth_token),
    )
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['blocked_reason'] == reason
