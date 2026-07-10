#!/bin/bash
# Build e push dell'immagine Docker su ECR
# Dopo il push, ECS fa il deploy automaticamente (nuovo task definition)
# Uso: ./scripts/deploy-backend.sh

set -e

PROJECT_NAME="learn-aws"
ENVIRONMENT="dev"
AWS_REGION="eu-north-1"
AWS_PROFILE="learn-aws"
ECR_REPO="${PROJECT_NAME}/${ENVIRONMENT}-backend"

echo "Logging into ECR..."
aws ecr get-login-password --region "$AWS_REGION" --profile "$AWS_PROFILE" | docker login --username AWS --password-stdin "$(aws sts get-caller-identity --query 'Account' --output text --profile "$AWS_PROFILE").dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "Building Docker image..."
cd be/src/container
docker build -t "$ECR_REPO" .

echo "Tagging image..."
ECR_URI="$(aws sts get-caller-identity --query 'Account' --output text --profile "$AWS_PROFILE").dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"
docker tag "$ECR_REPO:latest" "$ECR_URI:latest"

echo "Pushing to ECR..."
docker push "$ECR_URI:latest"

echo "Deploy complete!"
echo "ECS will pull the new image automatically."
