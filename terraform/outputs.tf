output "user_pool_id" {
  description = "ID del Cognito User Pool per login React"
  value = aws_cognito_user_pool.users.id
}

output "user_pool_client_id" {
  description = "Client ID per React Cognito"
  value = aws_cognito_user_pool_client.web_client.id
}

output "user_pool_arn" {
  description = "ARN del Cognito User Pool"
  value = aws_cognito_user_pool.users.arn
}

output "s3_bucket_name" {
  description = "Nome del bucket S3 per dati"
  value = aws_s3_bucket.data_bucket.bucket
}

output "s3_bucket_arn" {
  description = "ARN del bucket S3"
  value = aws_s3_bucket.data_bucket.arn
}

output "lambda_rest_function_name" {
  description = "Nome della Lambda REST API"
  value = aws_lambda_function.rest_api.function_name
}

output "lambda_rest_function_arn" {
  description = "ARN della Lambda REST API"
  value = aws_lambda_function.rest_api.arn
}

output "lambda_graphql_function_name" {
  description = "Nome della Lambda GraphQL API"
  value = aws_lambda_function.graphql_api.function_name
}

output "lambda_graphql_function_arn" {
  description = "ARN della Lambda GraphQL API"
  value = aws_lambda_function.graphql_api.arn
}

output "api_gateway_id" {
  description = "ID dell'API Gateway REST"
  value = aws_api_gateway_rest_api.api.id
}

output "api_gateway_arn" {
  description = "ARN dell'API Gateway REST"
  value = aws_api_gateway_rest_api.api.arn
}

output "appsync_api_id" {
  description = "ID dell'API AppSync GraphQL"
  value = aws_appsync_graphql_api.graphql.id
}

output "appsync_api_arn" {
  description = "ARN dell'API AppSync GraphQL"
  value = aws_appsync_graphql_api.graphql.arn
}

output "appsync_api_url" {
  description = "URL dell'API AppSync GraphQL"
  value = aws_appsync_graphql_api.graphql.uris.GRAPHQL
}
