output "secret_arn" {
  description = "Primary secret ARN for IAM policies and application configuration."
  value       = aws_secretsmanager_secret.this.arn
}

output "secret_name" {
  description = "Primary secret name or path."
  value       = aws_secretsmanager_secret.this.name
}

output "replica_regions" {
  description = "Sorted regions configured to receive replicas."
  value       = sort(keys(var.replica_regions))
}
