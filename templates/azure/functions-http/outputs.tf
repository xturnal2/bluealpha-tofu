output "resource_group_name" {
  description = "Created or reused resource group name."
  value       = local.resource_group_name
}

output "function_app_id" {
  description = "Function App resource ID."
  value       = azurerm_linux_function_app.this.id
}

output "function_app_name" {
  description = "Function App name."
  value       = azurerm_linux_function_app.this.name
}

output "default_hostname" {
  description = "Function App default hostname."
  value       = azurerm_linux_function_app.this.default_hostname
}

output "application_url" {
  description = "HTTPS base URL. It is unreachable when public access is disabled without separate private connectivity."
  value       = "https://${azurerm_linux_function_app.this.default_hostname}"
}

output "sample_health_url" {
  description = "URL for the included sample after it is published."
  value       = "https://${azurerm_linux_function_app.this.default_hostname}/api/health"
}

output "principal_id" {
  description = "System-assigned managed identity principal ID."
  value       = azurerm_linux_function_app.this.identity[0].principal_id
}

output "storage_account_name" {
  description = "Function runtime storage account name."
  value       = azurerm_storage_account.this.name
}

output "application_insights_id" {
  description = "Application Insights component ID."
  value       = azurerm_application_insights.this.id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID."
  value       = azurerm_log_analytics_workspace.this.id
}
