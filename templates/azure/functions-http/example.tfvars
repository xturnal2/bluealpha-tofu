project_name = "example"
environment  = "dev"
location     = "eastus"

plan_sku_name   = "Y1"
runtime_name    = "python"
runtime_version = "3.13"

# The endpoint is public. Add allow-list rules for production callers.
ip_restrictions = {
  office = {
    priority   = 100
    ip_address = "203.0.113.10/32"
  }
}

cors_allowed_origins = ["https://app.example.com"]

log_retention_days                       = 30
application_insights_sampling_percentage = 100
application_insights_daily_cap_gb        = 1

tags = {
  Owner      = "platform-team"
  CostCenter = "engineering"
}
