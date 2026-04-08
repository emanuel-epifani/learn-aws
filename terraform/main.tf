# 1. Cognito User Pool
resource "aws_cognito_user_pool" "users" {
  user_pool_name = "${var.project_name}-users"
  
  password_policy {
    minimum_length = 8
    require_lowercase = true
    require_numbers = true
    require_symbols = true
  }
  
  auto_verified_attributes = ["email"]
  
  username_attributes = ["email"]
}

# 2. Cognito User Pool Client
resource "aws_cognito_user_pool_client" "web_client" {
  user_pool_id = aws_cognito_user_pool.users.id
  client_name = "${var.project_name}-web-client"
  
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
  
  generate_secret = false
}

# 3. S3 Bucket per dati
resource "aws_s3_bucket" "data_bucket" {
  bucket = "${var.project_name}-data-${random_id.bucket_suffix.hex}"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_bucket_encryption" {
  bucket = aws_s3_bucket.data_bucket.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 4. IAM Role per Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# 5. IAM Policy per Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.data_bucket.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# 6. Lambda REST API
resource "aws_lambda_function" "rest_api" {
  function_name = "${var.project_name}-rest-api"
  runtime = var.lambda_runtime
  handler = "rest.handler"
  role = aws_iam_role.lambda_role.arn
  
  filename = "lambda_rest.zip"
  source_code_hash = filebase64sha256("lambda_rest.zip")
  
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.data_bucket.bucket
      USER_POOL_ID = aws_cognito_user_pool.users.id
    }
  }
}

# 7. Lambda GraphQL API
resource "aws_lambda_function" "graphql_api" {
  function_name = "${var.project_name}-graphql-api"
  runtime = var.lambda_runtime
  handler = "graphql.handler"
  role = aws_iam_role.lambda_role.arn
  
  filename = "lambda_graphql.zip"
  source_code_hash = filebase64sha256("lambda_graphql.zip")
  
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.data_bucket.bucket
      USER_POOL_ID = aws_cognito_user_pool.users.id
    }
  }
}

# 8. API Gateway REST
resource "aws_api_gateway_rest_api" "api" {
  name = "${var.project_name}-api"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# 9. Cognito Authorizer per API Gateway
resource "aws_api_gateway_authorizer" "cognito" {
  name = "cognito-authorizer"
  rest_api_id = aws_api_gateway_rest_api.api.id
  type = "COGNITO_USER_POOLS"
  
  provider_arns = [aws_cognito_user_pool.users.arn]
}

# 10. AppSync GraphQL API
resource "aws_appsync_graphql_api" "graphql" {
  name = "${var.project_name}-graphql"
  authentication_type = "AMAZON_COGNITO_USER_POOLS"
  
  user_pool_config {
    user_pool_id = aws_cognito_user_pool.users.id
    aws_region = var.aws_region
    default_action = "ALLOW"
  }
}
