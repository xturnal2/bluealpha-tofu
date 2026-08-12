output "event_bus_name" {
  description = "EventBridge custom event bus name."
  value       = aws_cloudwatch_event_bus.this.name
}

output "event_bus_arn" {
  description = "EventBridge custom event bus ARN."
  value       = aws_cloudwatch_event_bus.this.arn
}

output "archive_arn" {
  description = "Event archive ARN, or null when archiving is disabled."
  value       = try(aws_cloudwatch_event_archive.this[0].arn, null)
}
