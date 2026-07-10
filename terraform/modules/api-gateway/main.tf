# HTTP API Gateway
resource "aws_apigatewayv2_api" "this" {
  name          = "${var.project_name}-${var.environment}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "OPTIONS", "POST", "PUT", "DELETE"]
    allow_headers = ["Content-Type", "Authorization"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-api"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Integrazione: API Gateway -> Lambda (una per route)
resource "aws_apigatewayv2_integration" "lambda" {
  for_each         = var.routes
  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "AWS_PROXY"
  integration_uri  = each.value.integration_uri
}

# JWT Authorizer — Cognito
resource "aws_apigatewayv2_authorizer" "cognito_jwt" {
  api_id           = aws_apigatewayv2_api.this.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${var.project_name}-${var.environment}-cognito-jwt"

  jwt_configuration {
    audience = [var.cognito_client_id]
    issuer   = "https://cognito-idp.${var.aws_region}.amazonaws.com/${var.cognito_user_pool_id}"
  }
}

# Route: una per entry nella mappa
resource "aws_apigatewayv2_route" "this" {
  for_each           = var.routes
  api_id             = aws_apigatewayv2_api.this.id
  route_key          = each.value.route_key
  target             = "integrations/${aws_apigatewayv2_integration.lambda[each.key].id}"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_jwt.id
  authorization_type = "JWT"
}

# Stage con auto-deploy
resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.environment
  auto_deploy = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-api-stage"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Permesso: API Gateway puo invocare ogni Lambda
resource "aws_lambda_permission" "api_gateway" {
  for_each      = var.routes
  statement_id  = "AllowAPIGatewayInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
