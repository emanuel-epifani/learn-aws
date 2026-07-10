terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
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
  source             = "../../modules/iam"
  project_name       = var.project_name
  environment        = var.environment
  s3_bucket_arn      = module.s3.bucket_arn
  frontend_bucket_arn = module.frontend.frontend_bucket_arn
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

module "ecs" {
  source              = "../../modules/ecs"
  project_name        = var.project_name
  environment         = var.environment
  aws_region          = var.aws_region
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  alb_sg_id           = module.alb.alb_sg_id
  target_group_arn    = module.alb.target_group_arn
  ecr_repo_url        = module.ecr.repository_url
  execution_role_arn  = module.iam.ecs_task_execution_role_arn
  rds_endpoint        = module.rds.rds_endpoint
  db_name             = module.rds.rds_db_name
  db_username         = module.rds.rds_username
  db_password         = module.rds.rds_password
}

module "rds" {
  source                = "../../modules/rds"
  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  ecs_security_group_id = module.ecs.ecs_security_group_id
}

locals {
  lambdas = {
    presigned-url = {
      source_dir     = "${path.root}/../../../be/src/lambda/presigned-url"
      s3_bucket_name = module.s3.bucket_name
    }
    list-files = {
      source_dir     = "${path.root}/../../../be/src/lambda/list-files"
      s3_bucket_name = module.s3.bucket_name
    }
    download-file = {
      source_dir     = "${path.root}/../../../be/src/lambda/download-file"
      s3_bucket_name = module.s3.bucket_name
    }
    delete-file = {
      source_dir     = "${path.root}/../../../be/src/lambda/delete-file"
      s3_bucket_name = module.s3.bucket_name
    }
  }
}

module "lambda" {
  source   = "../../modules/lambda"
  for_each = local.lambdas

  project_name    = var.project_name
  environment     = var.environment
  lambda_role_arn = module.iam.lambda_role_arn

  source_dir     = each.value.source_dir
  s3_bucket_name = each.value.s3_bucket_name
}

module "api_gateway" {
  source       = "../../modules/api-gateway"
  project_name = var.project_name
  environment  = var.environment

  cognito_user_pool_id = module.cognito.user_pool_id
  cognito_client_id    = module.cognito.user_pool_client_id
  aws_region           = var.aws_region

  routes = {
    upload = {
      route_key       = "GET /upload"
      integration_uri = module.lambda["presigned-url"].lambda_invoke_arn
      function_name   = module.lambda["presigned-url"].lambda_function_name
    }
    list = {
      route_key       = "GET /files"
      integration_uri = module.lambda["list-files"].lambda_invoke_arn
      function_name   = module.lambda["list-files"].lambda_function_name
    }
    download = {
      route_key       = "GET /files/{key}/download"
      integration_uri = module.lambda["download-file"].lambda_invoke_arn
      function_name   = module.lambda["download-file"].lambda_function_name
    }
    delete = {
      route_key       = "DELETE /files/{key}"
      integration_uri = module.lambda["delete-file"].lambda_invoke_arn
      function_name   = module.lambda["delete-file"].lambda_function_name
    }
  }
}

module "frontend" {
  source       = "../../modules/frontend"
  project_name = var.project_name
  environment  = var.environment
}
