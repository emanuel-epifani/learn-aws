variable "project_name" {
  description = "Nome del progetto"
  type = string
  default = "learn-aws"
}

variable "aws_region" {
  description = "Regione AWS"
  type = string
  default = "eu-north-1"
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type = string
  default = "dev"
}

variable "lambda_runtime" {
  description = "Runtime per Lambda functions"
  type = string
  default = "nodejs18.x"
}

variable "lambda_timeout" {
  description = "Timeout massimo per Lambda functions in secondi"
  type = number
  default = 30
}

variable "lambda_memory_size" {
  description = "Memory allocation per Lambda functions in MB"
  type = number
  default = 256
}
