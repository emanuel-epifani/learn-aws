variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "ecr_repo_url" {
  type = string
}

variable "execution_role_arn" {
  type = string
}

variable "rds_endpoint" {
  type = string
}

variable "db_name" {
  type    = string
  default = "app"
}

variable "db_username" {
  type    = string
  default = "postgres"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "app_port" {
  type    = number
  default = 3000
}
