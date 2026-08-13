subscription_id = "00000000-0000-0000-0000-000000000000"
location        = "eastus"
project_name    = "example-api"
environment     = "dev"

sku_name                   = "standard"
soft_delete_retention_days = 90
purge_protection_enabled   = true

# Public access still requires Entra authentication and RBAC. Add CIDRs to
# restrict it, or disable it after separately creating private connectivity.
public_network_access_enabled = true
allowed_ip_cidrs              = []
allowed_subnet_ids            = []

role_assignments = {
  application = {
    principal_id = "11111111-1111-1111-1111-111111111111"
    role         = "Key Vault Secrets User"
  }
}

tags = {
  Owner      = "platform-team"
  CostCenter = "shared-services"
}
