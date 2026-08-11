output "topic_arn" {
  description = "SNS topic ARN for publishers and integrations."
  value       = aws_sns_topic.this.arn
}

output "topic_name" {
  description = "SNS topic name, including .fifo when applicable."
  value       = aws_sns_topic.this.name
}

output "topic_owner" {
  description = "AWS account ID that owns the topic."
  value       = aws_sns_topic.this.owner
}

output "subscription_arns" {
  description = "Subscription ARNs keyed by the configured stable labels. Pending confirmation endpoints may return pending confirmation."
  value       = { for key, subscription in aws_sns_topic_subscription.this : key => subscription.arn }
}
