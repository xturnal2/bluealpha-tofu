output "database_instance_id" {
  description = "RDS instance identifier."
  value       = aws_db_instance.this.identifier
}

output "database_instance_arn" {
  description = "RDS instance ARN."
  value       = aws_db_instance.this.arn
}

output "endpoint" {
  description = "PostgreSQL endpoint including port."
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "PostgreSQL endpoint hostname."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "PostgreSQL port."
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Initial database name."
  value       = aws_db_instance.this.db_name
}

output "security_group_id" {
  description = "Security group attached to the database."
  value       = aws_security_group.database.id
}

output "master_user_secret_arn" {
  description = "RDS-managed master secret ARN, or null when password management is disabled."
  value       = try(aws_db_instance.this.master_user_secret[0].secret_arn, null)
}
