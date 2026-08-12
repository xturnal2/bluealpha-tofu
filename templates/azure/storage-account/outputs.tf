output "storage_account_id" {
  description = "Storage account resource ID for RBAC and integrations."
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Globally unique storage account name."
  value       = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  description = "Primary HTTPS endpoint for Blob Storage."
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "identity_principal_id" {
  description = "Object ID of the storage account system-assigned managed identity."
  value       = azurerm_storage_account.this.identity[0].principal_id
}

output "container_ids" {
  description = "Private container resource IDs keyed by container name."
  value       = { for name, container in azurerm_storage_container.this : name => container.id }
}

output "resource_group_name" {
  description = "Resource group containing the storage account."
  value       = local.resource_group_name
}
