output "rds_endpoint" {
  value = aws_db_instance.this.address
}

output "rds_db_name" {
  value = aws_db_instance.this.db_name
}

output "rds_username" {
  value = aws_db_instance.this.username
}

output "rds_password" {
  value     = random_password.db.result
  sensitive = true
}
