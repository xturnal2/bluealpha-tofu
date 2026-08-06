project_name = "acme-docs"
environment  = "dev"
location     = "eastus"

# A globally unique, random-suffixed name is generated when this remains null.
storage_account_name = null

account_replication_type   = "LRS"
enable_versioning          = true
blob_delete_retention_days = 7

# Cost flag: enable for global edge caching and a Front Door endpoint.
enable_cdn = false

# Set false after all operators and deployment pipelines use Entra authentication.
enable_shared_access_key = true
create_sample_content    = true

tags = {
  Owner      = "web-team"
  CostCenter = "marketing"
}
