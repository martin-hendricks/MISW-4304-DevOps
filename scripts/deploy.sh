#!/usr/bin/env bash
# Dispatches continuous deployment based on DEPLOYMENT_PLATFORM (must match terraform deployment_platform).
#
#   DEPLOYMENT_PLATFORM=elastic_beanstalk   → scripts/deploy_eb.sh (ZIP + EB application version).
#   DEPLOYMENT_PLATFORM=ecs_fargate_codedeploy → scripts/deploy_ecs_codedeploy.sh (ECR + CodeDeploy ECS).
#
# Usage:
#   ./scripts/deploy.sh
#   DEPLOYMENT_PLATFORM=ecs_fargate_codedeploy ./scripts/deploy.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLATFORM="${DEPLOYMENT_PLATFORM:-elastic_beanstalk}"

case "$PLATFORM" in
  elastic_beanstalk)
    exec "$ROOT/scripts/deploy_eb.sh" "$@"
    ;;
  ecs_fargate_codedeploy)
    exec "$ROOT/scripts/deploy_ecs_codedeploy.sh" "$@"
    ;;
  *)
    echo "Unknown DEPLOYMENT_PLATFORM=${PLATFORM}; use elastic_beanstalk or ecs_fargate_codedeploy." >&2
    exit 1
    ;;
esac
