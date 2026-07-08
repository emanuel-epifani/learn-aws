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
