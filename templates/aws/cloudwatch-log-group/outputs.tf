output "log_group_arn" {
  description = "ARN of the CloudWatch log group."
  value       = aws_cloudwatch_log_group.this.arn
}

output "log_group_name" {
  description = "Name applications should use when publishing logs."
  value       = aws_cloudwatch_log_group.this.name
}

output "log_group_class" {
  description = "Storage class configured for the log group."
  value       = aws_cloudwatch_log_group.this.log_group_class
}
