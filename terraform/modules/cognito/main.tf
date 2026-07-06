# Cognito User Pool — database degli utenti
resource "aws_cognito_user_pool" "this" {
  name = "${var.project_name}-${var.environment}-user-pool"

  # email come attributo principale per login
  username_attributes = ["email"]

  # utenti possono registrarsi da soli
  auto_verified_attributes = ["email"]

  # password policy
  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
  }

  # verifica via email
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Verifica il tuo account - ${var.project_name}"
    email_message        = "Il tuo codice di verifica è {####}"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-user-pool"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# User Pool Client — l'app React
resource "aws_cognito_user_pool_client" "this" {
  name = "${var.project_name}-${var.environment}-client"

  user_pool_id = aws_cognito_user_pool.this.id

  # flow di autenticazione: username + password
  explicit_auth_flows = ["USER_PASSWORD_AUTH"]

  # il client non genera secret (per app web)
  generate_secret = false

  # durata dei token
  access_token_validity  = 60   # 60 minuti
  id_token_validity      = 60   # 60 minuti
  refresh_token_validity = 30   # 30 giorni

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}
