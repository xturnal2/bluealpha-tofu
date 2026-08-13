aws_region   = "us-east-1"
project_name = "example-app"
environment  = "dev"

retention_in_days           = 30
log_group_class             = "STANDARD"
deletion_protection_enabled = true
skip_destroy                = false

# Supply a symmetric KMS key ARN when customer-managed encryption is required.
# kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000000"

tags = {
  Owner      = "platform-team"
  CostCenter = "shared-services"
}
