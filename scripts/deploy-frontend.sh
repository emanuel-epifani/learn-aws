#!/bin/bash
# Deploy frontend su S3 static website hosting
# Uso: ./scripts/deploy-frontend.sh

set -e

PROJECT_NAME="learn-aws"
ENVIRONMENT="dev"
BUCKET="${PROJECT_NAME}-${ENVIRONMENT}-frontend"

echo "Building frontend..."
cd fe-react
npm run build

echo "Uploading to S3 bucket: $BUCKET"
aws s3 sync dist/ "s3://$BUCKET" --delete

echo "Deploy complete!"
echo "Website URL: http://${BUCKET}.s3-website.eu-north-1.amazonaws.com"
