terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

}

provider "aws" {
  region  = var.aws_region
  profile = "learn-aws"
}

module "vpc" {
  source       = "../../modules/vpc"
  project_name = var.project_name
  environment  = var.environment
}

module "cognito" {
  source       = "../../modules/cognito"
  project_name = var.project_name
  environment  = var.environment
}

module "s3" {
  source       = "../../modules/s3"
  project_name = var.project_name
  environment  = var.environment
}

module "iam" {
  source        = "../../modules/iam"
  project_name  = var.project_name
  environment   = var.environment
  s3_bucket_arn = module.s3.bucket_arn
}

module "ecr" {
  source       = "../../modules/ecr"
  project_name = var.project_name
  environment  = var.environment
}

module "alb" {
  source             = "../../modules/alb"
  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
}
