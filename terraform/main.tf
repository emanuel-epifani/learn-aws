# ============================================
# COGNITO - Autenticazione Utenti
# ============================================

resource "aws_cognito_user_pool" "users" {
  # User Pool per autenticazione utenti - gestisce registrazione, login, JWT tokens
  # Cognito User Pool gestisce l'autenticazione degli utenti, genera JWT tokens
  # utilizzati dal frontend React per accedere alle API protette
  name = "${var.project_name}-users"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
  }

  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]
}

resource "aws_cognito_user_pool_client" "web_client" {
  # Client per applicazione web React - usato per inizializzare AWS Cognito SDK
  # Cognito User Pool Client è l'applicazione che si connette al User Pool
  # Il frontend React usa questo client_id per inizializzare l'autenticazione
  user_pool_id = aws_cognito_user_pool.users.id
  name         = "${var.project_name}-web-client"

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  generate_secret = false  # false per SPA/React, true per server-side apps
}

# ============================================
# S3 - Storage Dati
# ============================================
resource "random_id" "bucket_suffix" {
  # Suffisso random per garantire unicità globale del nome bucket S3
  # Random ID per evitare conflitti di nomi bucket S3 (i nomi bucket devono essere globalmente unici)
  byte_length = 4
}

resource "aws_s3_bucket" "data_bucket" {
  # Bucket S3 per storage dati - le Lambda leggono/scrivono qui
  # S3 Bucket storage per i dati letti dalle Lambda functions
  # Usato per archiviare data.json e altri file statici
  bucket = "${var.project_name}-data-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_bucket_encryption" {
  # Configurazione encryption S3 - crittografa automaticamente tutti gli oggetti nel bucket
  # Server-side encryption per proteggere i dati a riposo in S3
  # AES256 è l'algoritmo di default di AWS per la crittografia S3
  bucket = aws_s3_bucket.data_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "data_bucket_versioning" {
  # Versioning S3 - mantiene storico delle versioni di ogni oggetto per recovery
  # Versioning S3 permette di mantenere multiple versioni di ogni oggetto
  # Utile per recovery accidentale e audit trail
  bucket = aws_s3_bucket.data_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "data_bucket_block" {
  # Blocca accessi pubblici al bucket S3 - best practice di sicurezza
  # Public access block impedisce accessi pubblici al bucket
  # Best practice di sicurezza: i bucket dovrebbero essere sempre privati di default
  bucket = aws_s3_bucket.data_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "data_json" {
  # Carica data.json nel bucket S3 - dati iniziali letti dalle Lambda
  # Pre-popola il bucket con data.json all'infrastruttura creation
  # Le Lambda functions leggono questo file per recuperare dati iniziali
  bucket = aws_s3_bucket.data_bucket.id
  key    = "data.json"
  source = "data/data.json"
  etag   = filemd5("data/data.json")
}

# ============================================
# IAM - Permessi Lambda
# ============================================

resource "aws_iam_role" "lambda_role" {
  # IAM Role per Lambda functions - permette di assumere permessi per accedere S3 e CloudWatch
  # IAM Role definisce quali servizi possono assumere questo ruolo
  # Lambda assume questo ruolo per ottenere permessi di accedere ad altre risorse AWS
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

resource "aws_iam_role_policy" "lambda_policy" {
  # Policy per Lambda - permessi S3 (read/write) e CloudWatch (logging)
  # IAM Policy definisce le azioni specifiche che il ruolo può eseguire
  # Qui permettiamo alle Lambda di leggere/scrivere su S3 e scrivere log su CloudWatch
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

# ============================================
# IAM - Permessi AppSync
# ============================================

resource "aws_iam_role" "appsync_role" {
  # IAM Role per AppSync datasource - permette ad AppSync di invocare Lambda
  # AppSync assume questo ruolo per accedere alla Lambda GraphQL
  name = "${var.project_name}-appsync-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "appsync.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "appsync_policy" {
  # Policy per AppSync - permesso di invocare Lambda GraphQL
  # IAM Policy permette ad AppSync di invocare la Lambda
  name = "${var.project_name}-appsync-policy"
  role = aws_iam_role.appsync_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "lambda:InvokeFunction"
        Resource = [
          for k, v in aws_lambda_function.graphql_functions : v.arn
        ]
      }
    ]
  })
}

# ============================================
# LAMBDA - Serverless Compute
# ============================================

resource "aws_lambda_function" "rest_functions" {
  # Lambda functions per API REST - valida JWT, legge da S3, restituisce dati JSON
  # Lambda REST API gestisce endpoint REST, valida JWT token e legge da S3
  # Richiamata da API Gateway quando arriva una request REST
  for_each = local.rest_lambdas

  function_name = "${var.project_name}-${each.value.name}"
  runtime       = var.lambda_runtime
  handler       = each.value.handler
  role          = aws_iam_role.lambda_role.arn

  filename         = each.value.source
  source_code_hash = filebase64sha256(each.value.source)

  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory_size

  environment {
    variables = {
      BUCKET_NAME  = aws_s3_bucket.data_bucket.bucket
      USER_POOL_ID = aws_cognito_user_pool.users.id
    }
  }
}

resource "aws_lambda_function" "graphql_functions" {
  # Lambda functions per API GraphQL - valida JWT, processa query, legge da S3
  # Lambda GraphQL API gestisce endpoint GraphQL, valida JWT token e legge da S3
  # Richiamata da AppSync quando arriva una query GraphQL
  for_each = local.graphql_lambdas

  function_name = "${var.project_name}-${each.value.name}"
  runtime       = var.lambda_runtime
  handler       = each.value.handler
  role          = aws_iam_role.lambda_role.arn

  filename         = each.value.source
  source_code_hash = filebase64sha256(each.value.source)

  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory_size

  environment {
    variables = {
      BUCKET_NAME  = aws_s3_bucket.data_bucket.bucket
      USER_POOL_ID = aws_cognito_user_pool.users.id
    }
  }
}

# ============================================
# Endpoint REST
# ============================================

resource "aws_api_gateway_rest_api" "api" {
  # API Gateway REST - container per endpoint HTTP REST
  # API Gateway REST è il container per l'API REST
  # Espone endpoint HTTPS che ricevono requests e le forward alle Lambda
  name        = "${var.project_name}-rest-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_authorizer" "cognito" {
  # Authorizer Cognito - valida JWT tokens nelle request API Gateway
  # Cognito Authorizer valida JWT tokens prima di permettere access alle API
  # Protegge gli endpoint assicurando che solo utenti autenticati possano accedere
  name        = "${var.project_name}-cognito-authorizer"
  rest_api_id = aws_api_gateway_rest_api.api.id
  type        = "COGNITO_USER_POOLS"

  provider_arns = [aws_cognito_user_pool.users.arn]
}

resource "aws_api_gateway_resource" "rest_resources" {
  # Resources per endpoint REST - path segments per endpoint dati
  # Resource definisce il path segment nell'URL (es. /data)
  # È parte della gerarchia API: API → Resource → Method → Integration
  for_each   = local.rest_lambdas
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id  = aws_api_gateway_rest_api.api.root_resource_id
  path_part  = each.value.path
}

resource "aws_api_gateway_method" "rest_methods" {
  # Methods per endpoint REST - HTTP methods per leggere dati
  # Method definisce l'HTTP method (GET, POST, PUT, DELETE) per una resource
  # Qui definiamo methods con autorizzazione Cognito
  for_each      = local.rest_lambdas
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.rest_resources[each.key].id
  http_method   = each.value.method
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "rest_integrations" {
  # Integrations per endpoint REST - collegano methods alle Lambda functions
  # Integration collega il method alla Lambda function
  # AWS_PROXY type passa direttamente l'evento alla Lambda senza transformation
  for_each             = local.rest_lambdas
  rest_api_id          = aws_api_gateway_rest_api.api.id
  resource_id          = aws_api_gateway_resource.rest_resources[each.key].id
  http_method          = aws_api_gateway_method.rest_methods[each.key].http_method
  type                 = "AWS_PROXY"

  integration_http_method = "POST"
  uri                     = aws_lambda_function.rest_functions[each.key].invoke_arn
}

resource "aws_api_gateway_deployment" "api" {
  # Deployment API Gateway - snapshot della configurazione API
  # Deployment crea una snapshot dell'API configuration
  # Necessario per deployare le changes all'API
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode([
      # Include tutte le risorse create con for_each
      aws_api_gateway_resource.rest_resources,
      aws_api_gateway_method.rest_methods,
      aws_api_gateway_integration.rest_integrations,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "dev" {
  # Stage dev - ambiente di sviluppo per API Gateway
  # Stage è l'ambiente di deployment (dev, staging, prod)
  # Espone l'API con un URL specifico dello stage
  deployment_id = aws_api_gateway_deployment.api.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "dev"
}

resource "aws_lambda_permission" "rest_api_gateway" {
  # Permessi API Gateway → Lambda - permettono ad API Gateway di invocare Lambda REST
  # Lambda Permission permette ad API Gateway di invocare la Lambda
  # Senza questo, API Gateway non può chiamare la Lambda (security boundary)
  for_each      = local.rest_lambdas
  statement_id  = "AllowAPIGatewayInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rest_functions[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}

# ============================================
# Endpoint GRAPHQL
# ============================================

resource "aws_appsync_graphql_api" "graphql" {
  # AppSync GraphQL API - managed GraphQL service con auth Cognito
  # AppSync GraphQL API è il managed GraphQL service di AWS
  # Fornisce endpoint GraphQL con subscription, caching, e auth integrata
  name                = "${var.project_name}-graphql-api"
  authentication_type = "AMAZON_COGNITO_USER_POOLS"
  schema              = file("${path.module}/../lambda/src/graphql/schema.graphql")

  user_pool_config {
    user_pool_id   = aws_cognito_user_pool.users.id
    aws_region     = var.aws_region
    default_action = "ALLOW"
  }
}

resource "aws_appsync_datasource" "graphql_datasources" {
  # Datasources Lambda - AppSync richiede dati dalle Lambda GraphQL
  # Datasource definisce da dove AppSync recupera i dati (Lambda, DynamoDB, HTTP, etc.)
  # Qui colleghiamo le Lambda GraphQL come datasource
  for_each       = local.graphql_lambdas
  api_id         = aws_appsync_graphql_api.graphql.id
  name           = "${var.project_name}_lambda_datasource_${each.key}"
  type           = "AWS_LAMBDA"
  service_role_arn = aws_iam_role.appsync_role.arn

  lambda_config {
    function_arn = aws_lambda_function.graphql_functions[each.key].arn
  }
}

resource "aws_appsync_resolver" "graphql_resolvers" {
  # Resolvers GraphQL - collegano campi schema alla Lambda datasource
  # Resolver collega un campo dello schema a un datasource
  # Qui colleghiamo i campi Query/Mutation alla Lambda
  for_each    = local.graphql_resolvers
  api_id      = aws_appsync_graphql_api.graphql.id
  type        = each.value.type
  field       = each.value.field
  data_source = aws_appsync_datasource.graphql_datasources["graphql_api"].name

  request_template = <<EOF
{
  "version": "2017-02-28",
  "operation": "Invoke",
  "payload": {
    "action": "${each.value.field}",
    "arguments": $utils.toJson($ctx.arguments)
  }
}
EOF

  response_template = <<EOF
#if($ctx.error)
  $util.error($ctx.error.message, $ctx.error.type)
#end
$util.toJson($ctx.result)
EOF
}

resource "aws_lambda_permission" "appsync" {
  # Permessi AppSync → Lambda - permettono ad AppSync di invocare Lambda GraphQL
  # Lambda Permission permette ad AppSync di invocare la Lambda
  # Senza questo, AppSync non può chiamare la Lambda (security boundary)
  for_each      = local.graphql_lambdas
  statement_id  = "AllowAppSyncInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.graphql_functions[each.key].function_name
  principal     = "appsync.amazonaws.com"
  source_arn    = aws_appsync_graphql_api.graphql.arn
}
