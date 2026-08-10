output "table_name" {
  description = "DynamoDB table name."
  value       = aws_dynamodb_table.this.name
}

output "table_arn" {
  description = "DynamoDB table ARN for IAM policies and integrations."
  value       = aws_dynamodb_table.this.arn
}

output "table_id" {
  description = "DynamoDB table ID."
  value       = aws_dynamodb_table.this.id
}

output "stream_arn" {
  description = "Latest DynamoDB stream ARN, or null when streams are disabled."
  value       = aws_dynamodb_table.this.stream_arn
}

output "stream_label" {
  description = "Latest DynamoDB stream timestamp label, or null when streams are disabled."
  value       = aws_dynamodb_table.this.stream_label
}

output "global_secondary_index_names" {
  description = "Configured global secondary index names."
  value       = sort(keys(var.global_secondary_indexes))
}

output "local_secondary_index_names" {
  description = "Configured local secondary index names."
  value       = sort(keys(var.local_secondary_indexes))
}
