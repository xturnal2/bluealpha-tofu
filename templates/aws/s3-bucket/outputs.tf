output "bucket_name" {
  description = "Globally unique S3 bucket name."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "S3 bucket ARN for IAM policies and integrations."
  value       = aws_s3_bucket.this.arn
}

output "regional_domain_name" {
  description = "Regional S3 hostname for the bucket."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "region" {
  description = "AWS region containing the bucket."
  value       = aws_s3_bucket.this.region
}
