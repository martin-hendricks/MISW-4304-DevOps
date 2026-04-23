import json


def test_auth_valid_credentials(client):
    response = client.post(
        '/auth/token',
        data=json.dumps({'username': 'testuser', 'password': 'testpassword'}),
        content_type='application/json',
    )
    assert response.status_code == 200
    data = json.loads(response.data)
    assert 'access_token' in data


def test_auth_invalid_password(client):
    response = client.post(
        '/auth/token',
        data=json.dumps({'username': 'testuser', 'password': 'wrongpassword'}),
        content_type='application/json',
    )
    assert response.status_code == 401
    data = json.loads(response.data)
    assert data['message'] == 'Invalid credentials'


def test_auth_invalid_username(client):
    response = client.post(
        '/auth/token',
        data=json.dumps({'username': 'wronguser', 'password': 'testpassword'}),
        content_type='application/json',
    )
    assert response.status_code == 401


def test_auth_missing_fields(client):
    response = client.post(
        '/auth/token',
        data=json.dumps({'username': 'testuser'}),
        content_type='application/json',
    )
    assert response.status_code == 400
    data = json.loads(response.data)
    assert 'message' in data


def test_auth_empty_body(client):
    response = client.post(
        '/auth/token',
        data='',
        content_type='application/json',
    )
    assert response.status_code == 400
    data = json.loads(response.data)
    assert 'message' in data


def test_auth_non_json_body(client):
    response = client.post(
        '/auth/token',
        data='not-json',
        content_type='text/plain',
    )
    assert response.status_code == 400
