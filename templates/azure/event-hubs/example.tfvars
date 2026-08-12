subscription_id = "00000000-0000-0000-0000-000000000000"
location        = "eastus"
project_name    = "example-api"
environment     = "dev"

sku                    = "Standard"
capacity               = 1
auto_inflate_enabled   = false
partition_count        = 4
message_retention_days = 1

local_authentication_enabled  = false
public_network_access_enabled = true

consumer_groups = {
  application = { user_metadata = "Primary application processor" }
}

role_assignments = {}

tags = {
  Owner      = "platform-team"
  CostCenter = "shared-services"
}
