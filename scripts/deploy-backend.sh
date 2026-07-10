#!/bin/bash
# Build e push dell'immagine Docker su ECR + force redeploy ECS
# Usa git-sha come tag immagine (coerente con la pipeline GitHub Actions)
# Uso: ./scripts/deploy-backend.sh

set -e

PROJECT_NAME="learn-aws"
ENVIRONMENT="dev"
AWS_REGION="eu-north-1"
AWS_PROFILE="learn-aws"
ECR_REPO="${PROJECT_NAME}/${ENVIRONMENT}-backend"
TASK_FAMILY="${PROJECT_NAME}-${ENVIRONMENT}-backend"
CLUSTER_NAME="${PROJECT_NAME}-${ENVIRONMENT}-cluster"
SERVICE_NAME="${PROJECT_NAME}-${ENVIRONMENT}-backend"
IMAGE_TAG=$(git rev-parse --short HEAD)

echo "Logging into ECR..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text --profile "$AWS_PROFILE")
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
aws ecr get-login-password --region "$AWS_REGION" --profile "$AWS_PROFILE" | docker login --username AWS --password-stdin "$ECR_URI"

echo "Building Docker image (tag: $IMAGE_TAG)..."
cd be/src/container
docker build -t "$ECR_REPO:$IMAGE_TAG" .

echo "Tagging and pushing to ECR..."
docker tag "$ECR_REPO:$IMAGE_TAG" "$ECR_URI/$ECR_REPO:$IMAGE_TAG"
docker push "$ECR_URI/$ECR_REPO:$IMAGE_TAG"

echo "Updating ECS task definition with new image..."
aws ecs describe-task-definition \
  --task-definition "$TASK_FAMILY" \
  --query taskDefinition \
  --profile "$AWS_PROFILE" > /tmp/task-def.json

jq --arg IMAGE "$ECR_URI/$ECR_REPO:$IMAGE_TAG" \
  '.containerDefinitions[0].image = $IMAGE' \
  /tmp/task-def.json > /tmp/task-def-updated.json

NEW_TASK_DEF_ARN=$(aws ecs register-task-definition \
  --cli-input-json file:///tmp/task-def-updated.json \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text \
  --profile "$AWS_PROFILE")

echo "Updating ECS service and forcing new deployment..."
aws ecs update-service \
  --cluster "$CLUSTER_NAME" \
  --service "$SERVICE_NAME" \
  --task-definition "$NEW_TASK_DEF_ARN" \
  --force-new-deployment \
  --profile "$AWS_PROFILE"

echo "Deploy complete! Image: $ECR_URI/$ECR_REPO:$IMAGE_TAG"
echo "ECS will pull the new image and restart the container."
