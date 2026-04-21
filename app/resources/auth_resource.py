import hmac

from flask import current_app, request
from flask_restful import Resource
from flask_jwt_extended import create_access_token


class AuthResource(Resource):
    def post(self):
        data = request.get_json(silent=True)
        if not data:
            return {'message': 'Request body must be valid JSON'}, 400

        username = data.get('username', '').strip()
        password = data.get('password', '')

        if not username or not password:
            return {'message': 'username and password are required'}, 400

        expected_username = current_app.config.get('SERVICE_USERNAME', '')
        expected_password = current_app.config.get('SERVICE_PASSWORD', '')

        # Use timing-safe comparison to prevent timing attacks
        username_match = hmac.compare_digest(username, expected_username)
        password_match = hmac.compare_digest(password, expected_password)
        # Use timing-safe comparison to prevent timing attacks

        if not username_match or not password_match:
            return {'message': 'Invalid credentials'}, 401

        access_token = create_access_token(identity=username)
        return {'access_token': access_token}, 200
