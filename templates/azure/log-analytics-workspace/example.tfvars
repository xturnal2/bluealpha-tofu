subscription_id = "00000000-0000-0000-0000-000000000000"
location        = "eastus"
project_name    = "example-app"
environment     = "dev"

retention_in_days            = 30
daily_quota_gb               = 1
sku                          = "PerGB2018"
local_authentication_enabled = false
internet_ingestion_enabled   = true
internet_query_enabled       = true

# Add workspace-scoped readers or contributors by object ID.
role_assignments = {
  # operators = {
  #   principal_id   = "11111111-1111-1111-1111-111111111111"
  #   role           = "Log Analytics Reader"
  #   principal_type = "Group"
  # }
}

tags = {
  Owner      = "platform-team"
  CostCenter = "shared-services"
}
