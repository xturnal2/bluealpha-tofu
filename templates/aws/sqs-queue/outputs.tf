output "queue_name" {
  description = "Source queue name."
  value       = aws_sqs_queue.this.name
}

output "queue_arn" {
  description = "Source queue ARN for IAM and event-source configuration."
  value       = aws_sqs_queue.this.arn
}

output "queue_url" {
  description = "Source queue URL for SDK and CLI operations."
  value       = aws_sqs_queue.this.url
}

output "dead_letter_queue_name" {
  description = "Dead-letter queue name, or null when disabled."
  value       = try(aws_sqs_queue.dead_letter[0].name, null)
}

output "dead_letter_queue_arn" {
  description = "Dead-letter queue ARN, or null when disabled."
  value       = try(aws_sqs_queue.dead_letter[0].arn, null)
}

output "dead_letter_queue_url" {
  description = "Dead-letter queue URL, or null when disabled."
  value       = try(aws_sqs_queue.dead_letter[0].url, null)
}
