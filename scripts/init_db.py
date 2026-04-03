import os
import time

from sqlalchemy import text

from app import create_app, db


def run_db_init() -> bool:
    max_retries = int(os.environ.get('DB_INIT_MAX_RETRIES', '10'))
    retry_delay = int(os.environ.get('DB_INIT_RETRY_DELAY_SECONDS', '5'))

    app = create_app()

    for attempt in range(1, max_retries + 1):
        try:
            with app.app_context():
                # Validates the connection before creating tables.
                db.session.execute(text('SELECT 1'))
                db.create_all()
            print('Database initialization completed successfully.')
            return True
        except Exception as exc:
            print(f'Database initialization attempt {attempt}/{max_retries} failed: {exc}')
            if attempt == max_retries:
                return False
            time.sleep(retry_delay)

    return False


if __name__ == '__main__':
    success = run_db_init()
    raise SystemExit(0 if success else 1)
