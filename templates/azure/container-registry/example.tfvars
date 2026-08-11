subscription_id = "00000000-0000-0000-0000-000000000000"
location        = "eastus"
project_name    = "example-api"
environment     = "dev"

sku                           = "Standard"
admin_enabled                 = false
anonymous_pull_enabled        = false
public_network_access_enabled = true

# Add application/build identities without storing registry credentials.
role_assignments = {
  runtime = {
    principal_id = "11111111-1111-1111-1111-111111111111"
    role         = "AcrPull"
  }
}

tags = {
  Owner      = "platform-team"
  CostCenter = "shared-services"
}
