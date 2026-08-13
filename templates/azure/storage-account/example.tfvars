subscription_id = "00000000-0000-0000-0000-000000000000"
location        = "eastus"
project_name    = "example-api"
environment     = "dev"

account_replication_type  = "LRS"
access_tier               = "Hot"
shared_access_key_enabled = false

versioning_enabled              = true
blob_delete_retention_days      = 30
container_delete_retention_days = 30

public_network_access_enabled = true
allowed_ip_rules              = []
allowed_subnet_ids            = []

containers = {
  application-data = {}
}

role_assignments = {
  application = {
    principal_id = "11111111-1111-1111-1111-111111111111"
    role         = "Storage Blob Data Contributor"
  }
}

tags = {
  Owner      = "platform-team"
  CostCenter = "shared-services"
}
