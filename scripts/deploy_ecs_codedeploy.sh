#!/usr/bin/env bash
# Build the Docker image, push to ECR, register a new task definition revision,
# and start a CodeDeploy ECS blue/green deployment (ALB listener 80 = prod, 8080 = test).
#
# Prerequisites:
#   - deployment_platform = "ecs_fargate_codedeploy" applied in Terraform (creates ECR, cluster, service).
#   - At least one image pushed to ECR if the ECS service has never started (e.g. push :latest once
#     before the first apply, or apply will fail when the service cannot pull the image).
#
# Env (optional overrides):
#   AWS_REGION, IMAGE_TAG, PROJECT_NAME, ENVIRONMENT (for default TF_DIR if TF_DIR unset)
#   TF_DIR  — default: ../terraform/environments/dev relative to repo root
#
# Usage:
#   ./scripts/deploy_ecs_codedeploy.sh
#   IMAGE_TAG=v1.2.3 ./scripts/deploy_ecs_codedeploy.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TF_DIR="${TF_DIR:-${ROOT}/terraform/environments/dev}"
REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"
export AWS_DEFAULT_REGION="$REGION"

IMAGE_TAG="${IMAGE_TAG:-rel-$(date -u +%Y%m%d-%H%M%S)}"

if ! command -v jq >/dev/null 2>&1; then
  echo "This script requires jq." >&2
  exit 1
fi

ECR_URL="$(terraform -chdir="$TF_DIR" output -raw ecs_ecr_repository_url)"
TASK_FAMILY="$(terraform -chdir="$TF_DIR" output -raw ecs_task_definition_family)"
CD_APP="$(terraform -chdir="$TF_DIR" output -raw ecs_codedeploy_application_name)"
CD_DG="$(terraform -chdir="$TF_DIR" output -raw ecs_codedeploy_deployment_group_name)"

FULL_IMAGE="${ECR_URL}:${IMAGE_TAG}"

echo "==> ECR login (${REGION})"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "${ECR_URL%%/*}"

echo "==> Build and push ${FULL_IMAGE}"
docker build -t "$FULL_IMAGE" "$ROOT"
docker tag "$FULL_IMAGE" "${ECR_URL}:latest"
docker push "$FULL_IMAGE"
docker push "${ECR_URL}:latest"

echo "==> Register task definition revision (family ${TASK_FAMILY})"
aws ecs describe-task-definition --task-definition "$TASK_FAMILY" --region "$REGION" --query taskDefinition \
  | jq 'del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)
      | (.containerDefinitions[] | select(.name == "app") | .image) = "'"$FULL_IMAGE"'"' \
  > /tmp/ecs-register-td.json

NEW_TD_ARN="$(
  aws ecs register-task-definition --cli-input-json file:///tmp/ecs-register-td.json \
    --region "$REGION" --query taskDefinition.taskDefinitionArn --output text
)"

APPSPEC_FILE="$(mktemp)"
trap 'rm -f /tmp/ecs-register-td.json "$APPSPEC_FILE"' EXIT

cat >"$APPSPEC_FILE" <<EOF
version: 0.0
Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: "${NEW_TD_ARN}"
        LoadBalancerInfo:
          ContainerName: "app"
          ContainerPort: 5000
EOF

CONTENT="$(cat "$APPSPEC_FILE")"
jq -n \
  --arg app "$CD_APP" \
  --arg dg "$CD_DG" \
  --arg content "$CONTENT" \
  '{
    applicationName: $app,
    deploymentGroupName: $dg,
    revision: {
      revisionType: "AppSpecContent",
      appSpecContent: { content: $content }
    }
  }' > /tmp/codedeploy-request.json

echo "==> CodeDeploy deployment (${CD_APP} / ${CD_DG})"
DEPLOY_ID="$(aws deploy create-deployment --cli-input-json file:///tmp/codedeploy-request.json \
  --region "$REGION" --query deploymentId --output text)"

echo "==> Started deployment ${DEPLOY_ID}"
echo "    aws deploy get-deployment --deployment-id ${DEPLOY_ID} --region ${REGION}"
