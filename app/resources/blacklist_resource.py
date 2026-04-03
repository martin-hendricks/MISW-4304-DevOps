import re
import uuid

from flask import request
from flask_restful import Resource
from flask_jwt_extended import jwt_required

from .. import db
from ..models.blacklist import BlacklistEmail

EMAIL_REGEX = re.compile(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')


def _is_valid_email(email):
    return bool(EMAIL_REGEX.match(email))


def _is_valid_uuid(value):
    try:
        uuid.UUID(str(value))
        return True
    except (ValueError, AttributeError):
        return False


def _get_client_ip():
    forwarded_for = request.headers.get('X-Forwarded-For')
    if forwarded_for:
        return forwarded_for.split(',')[0].strip()
    return request.remote_addr


class BlacklistResource(Resource):
    @jwt_required()
    def post(self):
        data = request.get_json(silent=True)
        if not data:
            return {'message': 'Request body must be valid JSON'}, 400

        email = data.get('email', '').strip()
        app_uuid = data.get('app_uuid', '').strip()
        blocked_reason = data.get('blocked_reason', None)

        if not email:
            return {'message': 'email is required'}, 400

        if not _is_valid_email(email):
            return {'message': 'email format is invalid'}, 400

        if not app_uuid:
            return {'message': 'app_uuid is required'}, 400

        if not _is_valid_uuid(app_uuid):
            return {'message': 'app_uuid must be a valid UUID'}, 400

        if blocked_reason is not None:
            if not isinstance(blocked_reason, str):
                return {'message': 'blocked_reason must be a string'}, 400
            blocked_reason = blocked_reason.strip()
            if len(blocked_reason) > 255:
                return {'message': 'blocked_reason must not exceed 255 characters'}, 400
            if blocked_reason == '':
                blocked_reason = None

        existing = BlacklistEmail.query.filter_by(email=email).first()
        if existing:
            return {'message': f'Email {email} is already in the blacklist'}, 409

        entry = BlacklistEmail(
            email=email,
            app_uuid=app_uuid,
            blocked_reason=blocked_reason,
            request_ip=_get_client_ip(),
        )

        db.session.add(entry)
        db.session.commit()

        return {'message': f'Email {email} was successfully added to the blacklist'}, 201


class BlacklistQueryResource(Resource):
    @jwt_required()
    def get(self, email):
        if not _is_valid_email(email):
            return {'message': 'email format is invalid'}, 400

        entry = BlacklistEmail.query.filter_by(email=email).first()

        if entry:
            return {
                'is_blacklisted': True,
                'blocked_reason': entry.blocked_reason,
            }, 200

        return {
            'is_blacklisted': False,
            'blocked_reason': None,
        }, 200
