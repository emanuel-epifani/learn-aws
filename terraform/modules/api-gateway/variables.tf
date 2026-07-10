variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "routes" {
  type = map(object({
    route_key       = string
    integration_uri = string
    function_name   = string
  }))
}

variable "cognito_user_pool_id" {
  type = string
}

variable "cognito_client_id" {
  type = string
}

variable "aws_region" {
  type = string
}
