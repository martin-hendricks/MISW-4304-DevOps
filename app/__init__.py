from flask import Flask, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_restful import Api
from flask_marshmallow import Marshmallow
from flask_jwt_extended import JWTManager
from sqlalchemy import text

db = SQLAlchemy()
ma = Marshmallow()
jwt = JWTManager()


def create_app(test_config=None):
    app = Flask(__name__)
    app.config.from_object('app.config.Config')
    if test_config is not None:
        app.config.from_object(test_config)
    # Flask-RESTful intercepta excepciones antes que los @jwt.*_loader de
    # Flask-JWT-Extended, devolviendo 500 en lugar de 401 sin token / token inválido.
    app.config['PROPAGATE_EXCEPTIONS'] = True

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

    @app.get('/')
    def health():
        return jsonify({'status': 'ok', 'message': 'pong'}), 200

    
    @app.get('/health')
    def ping():
        return jsonify({'status': 'ok', 'message': 'pong'}), 200


    api = Api(app)

    from .resources.blacklist_resource import BlacklistResource, BlacklistQueryResource
    from .resources.auth_resource import AuthResource

    api.add_resource(AuthResource, '/auth/token')
    api.add_resource(BlacklistResource, '/blacklists')
    api.add_resource(BlacklistQueryResource, '/blacklists/<string:email>')



    return app
