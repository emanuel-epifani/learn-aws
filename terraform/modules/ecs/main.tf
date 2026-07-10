# Security Group per ECS — permette ingresso solo dall'ALB
resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-${var.environment}-ecs-sg"
  description = "Allow ingress from ALB and all outbound"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Traffic from ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-${var.environment}-cluster"

  tags = {
    Name        = "${var.project_name}-${var.environment}-cluster"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Log Group per CloudWatch
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}-${var.environment}-backend"
  retention_in_days = 1

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Task Definition — cosa gira nel container
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.project_name}-${var.environment}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn

  container_definitions = jsonencode([
    {
      name  = "${var.project_name}-${var.environment}-backend"
      image = var.ecr_repo_url
      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "NODE_ENV"
          value = var.environment
        },
        {
          name  = "PORT"
          value = tostring(var.app_port)
        },
        {
          name  = "DB_HOST"
          value = var.rds_endpoint
        },
        {
          name  = "DB_PORT"
          value = "5432"
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        },
        {
          name  = "DB_USER"
          value = var.db_username
        },
        {
          name  = "DB_PASSWORD"
          value = var.db_password
        },
        {
          name  = "COGNITO_USER_POOL_ID"
          value = var.cognito_user_pool_id
        },
        {
          name  = "COGNITO_CLIENT_ID"
          value = var.cognito_client_id
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ECS Service — fa girare il container
resource "aws_ecs_service" "this" {
  name            = "${var.project_name}-${var.environment}-backend"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  # In dev usiamo public subnet + public IP per evitare NAT Gateway
  # In prod: private subnet + NAT Gateway o VPC Endpoints
  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "${var.project_name}-${var.environment}-backend"
    container_port   = var.app_port
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
