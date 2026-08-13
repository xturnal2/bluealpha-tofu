aws_region   = "us-east-1"
project_name = "example-api"
environment  = "dev"

# Same-account publishers can use identity policies instead of a bus policy.
allowed_put_events_principal_arns = []

enable_archive         = false
archive_retention_days = 30
archive_event_pattern = {
  source = ["com.example.orders"]
}

tags = {
  Owner      = "platform-team"
  CostCenter = "shared-services"
}
