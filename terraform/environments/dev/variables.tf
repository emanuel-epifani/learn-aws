variable "aws_region" {
  type    = string
  default = "eu-north-1"
}

variable "project_name" {
  type    = string
  default = "learn-aws"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "github_owner" {
  type        = string
  description = "GitHub username or organization that owns the repo"
}

variable "github_repository" {
  type        = string
  description = "GitHub repository name (without owner)"
}
