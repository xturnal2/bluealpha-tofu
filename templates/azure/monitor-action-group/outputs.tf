output "action_group_id" {
  description = "Resource ID consumed by Azure Monitor alerts."
  value       = azurerm_monitor_action_group.this.id
}
output "action_group_name" {
  description = "Name of the action group."
  value       = azurerm_monitor_action_group.this.name
}
output "resource_group_name" {
  description = "Resource group containing the action group."
  value       = local.resource_group_name
}
