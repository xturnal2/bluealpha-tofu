output "namespace_id" {
  description = "Event Hubs namespace resource ID."
  value       = azurerm_eventhub_namespace.this.id
}

output "namespace_name" {
  description = "Event Hubs namespace name."
  value       = azurerm_eventhub_namespace.this.name
}

output "eventhub_id" {
  description = "Event Hub entity resource ID."
  value       = azurerm_eventhub.this.id
}

output "eventhub_name" {
  description = "Event Hub entity name."
  value       = azurerm_eventhub.this.name
}

output "consumer_group_ids" {
  description = "Consumer group IDs keyed by name."
  value       = { for name, group in azurerm_eventhub_consumer_group.this : name => group.id }
}

output "identity_principal_id" {
  description = "Namespace system-assigned managed identity object ID."
  value       = azurerm_eventhub_namespace.this.identity[0].principal_id
}

output "resource_group_name" {
  description = "Resource group containing Event Hubs."
  value       = local.resource_group_name
}
