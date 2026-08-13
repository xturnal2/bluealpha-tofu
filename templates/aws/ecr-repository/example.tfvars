aws_region   = "us-east-1"
project_name = "example-api"
environment  = "dev"

# Safe defaults are immutable tags, scan-on-push, and bounded retention.
image_tag_mutability    = "IMMUTABLE"
scan_on_push            = true
enable_lifecycle_policy = true
untagged_retention_days = 14
max_image_count         = 50

# Add explicit IAM principal ARNs only for cross-account workflows.
allowed_pull_principal_arns = []
allowed_push_principal_arns = []

tags = {
  Owner      = "platform-team"
  CostCenter = "shared-services"
}
