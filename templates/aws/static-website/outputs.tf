output "bucket_name" {
  description = "Name of the private S3 origin bucket."
  value       = aws_s3_bucket.site.id
}

output "bucket_arn" {
  description = "ARN of the private S3 origin bucket."
  value       = aws_s3_bucket.site.arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID, useful for cache invalidations."
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution."
  value       = aws_cloudfront_distribution.site.arn
}

output "cloudfront_domain_name" {
  description = "CloudFront hostname to use directly or as a DNS alias target."
  value       = aws_cloudfront_distribution.site.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted zone ID for Route 53 alias records."
  value       = aws_cloudfront_distribution.site.hosted_zone_id
}

output "website_url" {
  description = "Preferred HTTPS URL, using the first custom alias when configured."
  value       = length(var.aliases) > 0 ? "https://${var.aliases[0]}" : "https://${aws_cloudfront_distribution.site.domain_name}"
}

output "access_log_bucket_name" {
  description = "CloudFront access log bucket name, or null when logging is disabled."
  value       = try(aws_s3_bucket.access_logs[0].id, null)
}

output "content_upload_command" {
  description = "Example AWS CLI command for uploading a built site."
  value       = "aws s3 sync ./dist s3://${aws_s3_bucket.site.id}/ --delete"
}

output "cache_invalidation_command" {
  description = "Example AWS CLI command for invalidating cached content."
  value       = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.site.id} --paths '/*'"
}
