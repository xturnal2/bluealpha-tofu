output "topic_id" {
  description = "Event Grid topic resource ID for RBAC and subscriptions."
  value       = azurerm_eventgrid_topic.this.id
}

output "topic_name" {
  description = "Event Grid custom topic name."
  value       = azurerm_eventgrid_topic.this.name
}

output "topic_endpoint" {
  description = "Publisher endpoint. Authentication is required according to local_auth_enabled."
  value       = azurerm_eventgrid_topic.this.endpoint
}

output "identity_principal_id" {
  description = "Object ID of the topic system-assigned managed identity."
  value       = azurerm_eventgrid_topic.this.identity[0].principal_id
}

output "event_subscription_ids" {
  description = "Event subscription resource IDs keyed by configured label."
  value       = { for key, subscription in azurerm_eventgrid_event_subscription.this : key => subscription.id }
}

output "resource_group_name" {
  description = "Resource group containing the topic."
  value       = local.resource_group_name
}
