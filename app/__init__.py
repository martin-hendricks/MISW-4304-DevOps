from flask import Flask, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_restful import Api
from flask_marshmallow import Marshmallow
from flask_jwt_extended import JWTManager

db = SQLAlchemy()
ma = Marshmallow()
jwt = JWTManager()


def create_app():
    app = Flask(__name__)
    app.config.from_object('app.config.Config')

    db.init_app(app)
    ma.init_app(app)
    jwt.init_app(app)

    # JWT error handlers
    @jwt.unauthorized_loader
    def missing_token_callback(error):
        return jsonify({'message': 'Authorization token is missing'}), 401

    @jwt.invalid_token_loader
    def invalid_token_callback(error):
        return jsonify({'message': 'Invalid authorization token'}), 401

    @jwt.expired_token_loader
    def expired_token_callback(jwt_header, jwt_payload):
        return jsonify({'message': 'Authorization token has expired'}), 401

    api = Api(app)

    from .resources.blacklist_resource import BlacklistResource, BlacklistQueryResource
    from .resources.auth_resource import AuthResource

    api.add_resource(AuthResource, '/auth/token')
    api.add_resource(BlacklistResource, '/blacklists')
    api.add_resource(BlacklistQueryResource, '/blacklists/<string:email>')

    with app.app_context():
        db.create_all()

    return app
