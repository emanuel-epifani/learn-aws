// networks
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

// cognito
output "user_pool_id" {
  value = module.cognito.user_pool_id
}

output "user_pool_client_id" {
  value = module.cognito.user_pool_client_id
}

// s3
output "s3_bucket_name" {
  value = module.s3.bucket_name
}

output "s3_bucket_arn" {
  value = module.s3.bucket_arn
}

// iam
output "ecs_task_execution_role_arn" {
  value = module.iam.ecs_task_execution_role_arn
}

output "lambda_role_arn" {
  value = module.iam.lambda_role_arn
}

// ecr
output "ecr_repository_url" {
  value = module.ecr.repository_url
}

// alb
output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "alb_sg_id" {
  value = module.alb.alb_sg_id
}

output "target_group_arn" {
  value = module.alb.target_group_arn
}

// ecs
output "ecs_security_group_id" {
  value = module.ecs.ecs_security_group_id
}

output "ecs_cluster_name" {
  value = module.ecs.ecs_cluster_name
}

// rds
output "rds_endpoint" {
  value = module.rds.rds_endpoint
}

output "rds_username" {
  value = module.rds.rds_username
}

output "rds_password" {
  value     = module.rds.rds_password
  sensitive = true
}

// lambda
output "lambda_function_names" {
  value = { for k, v in module.lambda : k => v.lambda_function_name }
}

output "lambda_function_arns" {
  value = { for k, v in module.lambda : k => v.lambda_function_arn }
}

// api gateway
output "api_endpoint" {
  value = module.api_gateway.api_endpoint
}
