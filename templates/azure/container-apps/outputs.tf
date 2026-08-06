output "resource_group_name" {
  description = "Created or reused resource group name."
  value       = local.resource_group_name
}

output "container_app_environment_id" {
  description = "Container Apps environment ID."
  value       = azurerm_container_app_environment.this.id
}

output "container_app_id" {
  description = "Container App resource ID."
  value       = azurerm_container_app.this.id
}

output "container_app_name" {
  description = "Container App name."
  value       = azurerm_container_app.this.name
}

output "latest_revision_name" {
  description = "Latest Container App revision name."
  value       = azurerm_container_app.this.latest_revision_name
}

output "fqdn" {
  description = "Ingress FQDN, or null when ingress is disabled."
  value       = try(azurerm_container_app.this.ingress[0].fqdn, null)
}

output "application_url" {
  description = "HTTPS application URL, or null when ingress is disabled. Internal ingress requires network connectivity."
  value       = try("https://${azurerm_container_app.this.ingress[0].fqdn}", null)
}

output "principal_id" {
  description = "System-assigned managed identity principal ID."
  value       = azurerm_container_app.this.identity[0].principal_id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID."
  value       = azurerm_log_analytics_workspace.this.id
}
