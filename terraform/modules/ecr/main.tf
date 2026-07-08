# ECR — registry privato per le Docker image
resource "aws_ecr_repository" "this" {
  name                 = "${var.project_name}/${var.environment}-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecr"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
