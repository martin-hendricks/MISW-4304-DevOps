#!/bin/sh
# Optional DB migrations / schema before Gunicorn (see README: RUN_DB_INIT, DB_INIT_REQUIRED).
# PYTHONPATH=/app so "from app import ..." works when the script lives under scripts/.
if [ "${RUN_DB_INIT:-false}" = "true" ]; then
  if ! PYTHONPATH=/app python /app/scripts/init_db.py; then
    echo "Database initialization failed."
    if [ "${DB_INIT_REQUIRED:-false}" = "true" ]; then
      exit 1
    fi
  fi
fi

exec "$@"
