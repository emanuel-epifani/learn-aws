# S3 bucket — file storage per File Bin
resource "aws_s3_bucket" "this" {
  bucket = "${var.project_name}-${var.environment}-filebin"

  tags = {
    Name        = "${var.project_name}-${var.environment}-filebin"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Blocca accesso pubblico
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CORS — permette al frontend di fare PUT/GET diretto su S3
resource "aws_s3_bucket_cors_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
