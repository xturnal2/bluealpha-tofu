output "repository_name" {
  description = "ECR repository name."
  value       = aws_ecr_repository.this.name
}

output "repository_arn" {
  description = "ECR repository ARN for IAM policies and integrations."
  value       = aws_ecr_repository.this.arn
}

output "repository_url" {
  description = "Registry hostname and repository path used to tag and push images."
  value       = aws_ecr_repository.this.repository_url
}

output "registry_id" {
  description = "AWS account registry ID that owns the repository."
  value       = aws_ecr_repository.this.registry_id
}
