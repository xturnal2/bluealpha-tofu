output "workspace_id" {
  description = "Azure resource ID of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

output "workspace_name" {
  description = "Name of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.name
}

output "workspace_customer_id" {
  description = "Non-secret workspace/customer ID used by compatible integrations."
  value       = azurerm_log_analytics_workspace.this.workspace_id
}

output "resource_group_name" {
  description = "Resource group containing the workspace."
  value       = local.resource_group_name
}
