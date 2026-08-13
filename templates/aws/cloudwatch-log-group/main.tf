locals {
  name = coalesce(var.log_group_name, "/${var.project_name}/${var.environment}/application")

  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "aws/cloudwatch-log-group"
  })
}

resource "aws_cloudwatch_log_group" "this" {
  name                        = local.name
  retention_in_days           = var.retention_in_days
  kms_key_id                  = var.kms_key_arn
  log_group_class             = var.log_group_class
  deletion_protection_enabled = var.deletion_protection_enabled
  skip_destroy                = var.skip_destroy
  tags                        = local.common_tags
}
