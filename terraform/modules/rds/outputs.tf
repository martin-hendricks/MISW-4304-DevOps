output "endpoint" {
  value       = aws_db_instance.this.address
  description = "RDS hostname (no port)."
}

output "port" {
  value       = aws_db_instance.this.port
  description = "Database port."
}

output "db_name" {
  value       = aws_db_instance.this.db_name
  description = "Database name."
}

output "username" {
  value       = var.db_username
  sensitive   = true
  description = "Master username."
}

output "password" {
  value       = random_password.master.result
  sensitive   = true
  description = "Master password (store securely; also in Terraform state)."
}

output "database_url" {
  value       = "postgresql+psycopg://${var.db_username}:${random_password.master.result}@${aws_db_instance.this.address}:${aws_db_instance.this.port}/${var.db_name}"
  sensitive   = true
  description = "SQLAlchemy/psycopg connection URL for the Flask app."
}
