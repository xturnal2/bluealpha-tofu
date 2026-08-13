output "registry_id" {
  description = "Azure Container Registry resource ID."
  value       = azurerm_container_registry.this.id
}

output "registry_name" {
  description = "Globally unique registry name."
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "Registry hostname used for image tags and Docker login."
  value       = azurerm_container_registry.this.login_server
}

output "identity_principal_id" {
  description = "Object ID of the registry system-assigned managed identity."
  value       = azurerm_container_registry.this.identity[0].principal_id
}

output "resource_group_name" {
  description = "Resource group containing the registry."
  value       = local.resource_group_name
}
