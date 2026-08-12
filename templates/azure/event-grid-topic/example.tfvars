subscription_id = "00000000-0000-0000-0000-000000000000"
location        = "eastus"
project_name    = "example-api"
environment     = "dev"

input_schema                  = "EventGridSchema"
local_auth_enabled            = false
public_network_access_enabled = true
allowed_ip_cidrs              = []

publisher_role_assignments = {
  application = {
    principal_id = "11111111-1111-1111-1111-111111111111"
  }
}

# Endpoint IDs must exist and authorize Event Grid delivery.
event_subscriptions = {}

tags = {
  Owner      = "platform-team"
  CostCenter = "shared-services"
}
