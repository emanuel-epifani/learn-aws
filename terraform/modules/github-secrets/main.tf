terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

# GitHub Actions Secrets — scritti automaticamente da Terraform
# Dopo terraform apply, i secret su GitHub sono aggiornati senza copia manuale

# Credenziali AWS per le pipeline di deploy (IAM user github_actions)
resource "github_actions_secret" "aws_access_key_id" {
  repository      = var.github_repository
  secret_name     = "AWS_ACCESS_KEY_ID"
  plaintext_value = var.aws_access_key_id
}

resource "github_actions_secret" "aws_secret_access_key" {
  repository      = var.github_repository
  secret_name     = "AWS_SECRET_ACCESS_KEY"
  plaintext_value = var.aws_secret_access_key
}

# Endpoint per il frontend (usati a build-time da Vite)
resource "github_actions_secret" "alb_endpoint" {
  repository      = var.github_repository
  secret_name     = "VITE_ALB_ENDPOINT"
  plaintext_value = var.alb_endpoint
}

resource "github_actions_secret" "api_endpoint" {
  repository      = var.github_repository
  secret_name     = "VITE_API_ENDPOINT"
  plaintext_value = var.api_endpoint
}

# Cognito (usati a build-time da Vite per Amplify)
resource "github_actions_secret" "cognito_user_pool_id" {
  repository      = var.github_repository
  secret_name     = "VITE_COGNITO_USER_POOL_ID"
  plaintext_value = var.cognito_user_pool_id
}

resource "github_actions_secret" "cognito_client_id" {
  repository      = var.github_repository
  secret_name     = "VITE_COGNITO_CLIENT_ID"
  plaintext_value = var.cognito_client_id
}
