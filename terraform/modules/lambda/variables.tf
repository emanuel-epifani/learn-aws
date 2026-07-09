variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}

variable "lambda_role_arn" {
  type = string
}

variable "source_dir" {
  type = string
}

variable "handler" {
  type    = string
  default = "index.handler"
}

variable "runtime" {
  type    = string
  default = "nodejs20.x"
}
