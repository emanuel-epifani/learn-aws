variable "github_owner" {
  type        = string
  description = "GitHub username or organization that owns the repo"
}

variable "github_repository" {
  type        = string
  description = "GitHub repository name (without owner)"
}

variable "aws_access_key_id" {
  type      = string
  sensitive = true
}

variable "aws_secret_access_key" {
  type      = string
  sensitive = true
}

variable "alb_endpoint" {
  type = string
}

variable "api_endpoint" {
  type = string
}

variable "cognito_user_pool_id" {
  type = string
}

variable "cognito_client_id" {
  type = string
}
