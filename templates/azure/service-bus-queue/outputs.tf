output "resource_group_name" {
  description = "Created or reused resource group name."
  value       = local.resource_group_name
}

output "namespace_id" {
  description = "Service Bus namespace resource ID."
  value       = azurerm_servicebus_namespace.this.id
}

output "namespace_name" {
  description = "Service Bus namespace name."
  value       = azurerm_servicebus_namespace.this.name
}

output "namespace_endpoint" {
  description = "Service Bus namespace endpoint."
  value       = azurerm_servicebus_namespace.this.endpoint
}

output "namespace_identity_principal_id" {
  description = "Namespace system-assigned managed identity principal ID."
  value       = azurerm_servicebus_namespace.this.identity[0].principal_id
}

output "queue_id" {
  description = "Service Bus queue resource ID."
  value       = azurerm_servicebus_queue.this.id
}

output "queue_name" {
  description = "Service Bus queue name."
  value       = azurerm_servicebus_queue.this.name
}

output "dead_letter_path" {
  description = "Entity path for the queue's built-in dead-letter subqueue."
  value       = "${azurerm_servicebus_queue.this.name}/$DeadLetterQueue"
}
