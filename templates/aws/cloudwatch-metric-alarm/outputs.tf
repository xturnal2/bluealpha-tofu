output "alarm_arn" {
  description = "ARN of the CloudWatch alarm."
  value       = aws_cloudwatch_metric_alarm.this.arn
}

output "alarm_name" {
  description = "Name of the CloudWatch alarm."
  value       = aws_cloudwatch_metric_alarm.this.alarm_name
}

output "alarm_id" {
  description = "Provider identifier of the alarm."
  value       = aws_cloudwatch_metric_alarm.this.id
}
