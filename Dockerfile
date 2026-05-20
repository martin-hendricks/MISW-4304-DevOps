FROM public.ecr.aws/docker/library/python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

ENV NEW_RELIC_APP_NAME="blacklist-service-prod" \
    NEW_RELIC_CONFIG_FILE=/app/newrelic.ini \
    NEW_RELIC_LOG=stdout \
    NEW_RELIC_DISTRIBUTED_TRACING_ENABLED=true \
    NEW_RELIC_LICENSE_KEY=e0dfb9982290970324a31a0e2ad7faa601f9NRAL \
    NEW_RELIC_LOG_LEVEL=info

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir newrelic

COPY . .
RUN chmod +x /app/entrypoint.sh

EXPOSE 5000

ENTRYPOINT ["newrelic-admin", "run-program", "/bin/sh", "/app/entrypoint.sh"]
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--threads", "4", "--timeout", "120", "run:application"]
