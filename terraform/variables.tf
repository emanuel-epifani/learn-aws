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
