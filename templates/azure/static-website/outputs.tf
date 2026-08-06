output "resource_group_name" {
  description = "Name of the created or reused resource group."
  value       = local.resource_group_name
}

output "storage_account_name" {
  description = "Name of the storage account containing the $web container."
  value       = azurerm_storage_account.site.name
}

output "storage_account_id" {
  description = "ID of the website storage account."
  value       = azurerm_storage_account.site.id
}

output "storage_website_url" {
  description = "Direct HTTPS endpoint for the storage static website."
  value       = azurerm_storage_account.site.primary_web_endpoint
}

output "frontdoor_endpoint_url" {
  description = "Azure Front Door HTTPS endpoint, or null when CDN is disabled."
  value       = try("https://${azurerm_cdn_frontdoor_endpoint.site[0].host_name}", null)
}

output "content_upload_command" {
  description = "Example Azure CLI command for uploading a built site with Entra authentication."
  value       = "az storage blob upload-batch --account-name ${azurerm_storage_account.site.name} --auth-mode login --destination '$web' --source ./dist --overwrite"
}
