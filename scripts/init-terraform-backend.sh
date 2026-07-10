#!/bin/bash
# Crea le risorse necessarie per il remote state di Terraform:
# - S3 bucket per il state file
# - DynamoDB table per il lock
# Queste risorse NON possono essere gestite da Terraform stesso (chicken-and-egg)
# Uso: ./scripts/init-terraform-backend.sh

set -e

PROJECT_NAME="learn-aws"
ENVIRONMENT="dev"
AWS_REGION="eu-north-1"
AWS_PROFILE="learn-aws"
STATE_BUCKET="${PROJECT_NAME}-${ENVIRONMENT}-tf-state"
LOCK_TABLE="${PROJECT_NAME}-${ENVIRONMENT}-tf-locks"

echo "Creating S3 bucket for Terraform state: $STATE_BUCKET"
aws s3api create-bucket \
  --bucket "$STATE_BUCKET" \
  --region "$AWS_REGION" \
  --create-bucket-configuration "LocationConstraint=$AWS_REGION" \
  --profile "$AWS_PROFILE"

echo "Enabling versioning on state bucket..."
aws s3api put-bucket-versioning \
  --bucket "$STATE_BUCKET" \
  --versioning-configuration Status=Enabled \
  --profile "$AWS_PROFILE"

echo "Creating DynamoDB table for Terraform locks: $LOCK_TABLE"
aws dynamodb create-table \
  --table-name "$LOCK_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$AWS_REGION" \
  --profile "$AWS_PROFILE"

echo ""
echo "Backend resources created!"
echo "S3 bucket: $STATE_BUCKET"
echo "DynamoDB:  $LOCK_TABLE"
echo ""
echo "Now update terraform/environments/dev/main.tf with the backend config."
