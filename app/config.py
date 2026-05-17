import os
from datetime import timedelta
from dotenv import load_dotenv

load_dotenv()


class Config:
    ##Config BD
    SQLALCHEMY_DATABASE_URI = os.environ.get(
        'DATABASE_URL',
        'postgresql+psycopg://user:password@localhost:5432/blacklist_db'
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY', 'change-this-to-a-strong-secret-key')
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(
        hours=int(os.environ.get('JWT_EXPIRES_HOURS', 24))
    )

    SERVICE_USERNAME = os.environ.get('SERVICE_USERNAME', 'admin')
    SERVICE_PASSWORD = os.environ.get('SERVICE_PASSWORD', 'change-this-password')