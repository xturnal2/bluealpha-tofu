output "role_arn" {
  description = "ARN used by workloads and resource policies."
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the IAM role."
  value       = aws_iam_role.this.name
}

output "role_id" {
  description = "Stable unique identifier assigned by IAM."
  value       = aws_iam_role.this.unique_id
}

output "managed_policy_attachment_ids" {
  description = "Managed policy attachment IDs keyed by policy ARN."
  value       = { for arn, attachment in aws_iam_role_policy_attachment.this : arn => attachment.id }
}
