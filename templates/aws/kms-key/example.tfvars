aws_region   = "us-east-1"
project_name = "example-api"
environment  = "dev"

enable_key_rotation     = true
rotation_period_in_days = 365
deletion_window_in_days = 30
multi_region            = false

allowed_key_administrator_arns = []
allowed_cryptographic_user_arns = [
  "arn:aws:iam::123456789012:role/example-api-runtime"
]

tags = {
  Owner      = "security-team"
  CostCenter = "shared-services"
}
