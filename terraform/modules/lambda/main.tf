# Zippa il codice Node.js per Lambda
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/dist/${basename(var.source_dir)}.zip"
}

# Lambda function per generare presigned URL
resource "aws_lambda_function" "this" {
  function_name    = "${var.project_name}-${var.environment}-${basename(var.source_dir)}"
  role             = var.lambda_role_arn
  handler          = var.handler
  runtime          = var.runtime
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = var.s3_bucket_name
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-${basename(var.source_dir)}"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

