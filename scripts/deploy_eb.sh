#!/usr/bin/env bash
# Zip the app (excludes terraform via explicit file list), upload to the EB S3 bucket,
# register an application version, and update the environment.
#
# Usage:
#   ./scripts/deploy_eb.sh
#   EB_ENVIRONMENT_NAME=my-env EB_APPLICATION_NAME=my-app ./scripts/deploy_eb.sh
#   EB_VERSION_LABEL=app-manual-1 ./scripts/deploy_eb.sh
#
# Requires: aws CLI, zip, credentials with EB + S3 permissions.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_NAME="${EB_APPLICATION_NAME:-blacklist-svc-dev-app}"
ENV_NAME="${EB_ENVIRONMENT_NAME:-blacklist-svc-dev-env}"
REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"
S3_PREFIX="${EB_S3_PREFIX:-blacklist-svc-dev}"

export AWS_DEFAULT_REGION="$REGION"

VERSION_LABEL="${EB_VERSION_LABEL:-app-$(date -u +%Y%m%d-%H%M%S)}"
ZIP="$(mktemp "/tmp/eb-blacklist-${VERSION_LABEL}.XXXXXX.zip")"
trap 'rm -f "$ZIP"' EXIT

echo "==> Building zip from ${ROOT}"
zip -qr "$ZIP" \
  Dockerfile entrypoint.sh requirements.txt run.py app scripts .dockerignore .ebignore README.md \
  -x "*__pycache__/*" -x "*.pyc"

ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"
BUCKET="elasticbeanstalk-${REGION}-${ACCOUNT}"
KEY="${S3_PREFIX}/${VERSION_LABEL}.zip"

echo "==> Uploading s3://${BUCKET}/${KEY}"
aws s3 cp "$ZIP" "s3://${BUCKET}/${KEY}"

echo "==> Creating application version ${VERSION_LABEL}"
aws elasticbeanstalk create-application-version \
  --application-name "$APP_NAME" \
  --version-label "$VERSION_LABEL" \
  --source-bundle "S3Bucket=${BUCKET},S3Key=${KEY}" \
  --process

echo "==> Updating environment ${ENV_NAME}"
aws elasticbeanstalk update-environment \
  --environment-name "$ENV_NAME" \
  --version-label "$VERSION_LABEL"

echo "==> Done. Version: ${VERSION_LABEL}"
echo "    Watch progress: aws elasticbeanstalk describe-events --environment-name ${ENV_NAME} --max-items 10"
