output "budget_id" {
  description = "Azure resource ID of the subscription budget."
  value       = azurerm_consumption_budget_subscription.this.id
}

output "budget_name" {
  description = "Name of the subscription budget."
  value       = azurerm_consumption_budget_subscription.this.name
}

output "budget_amount" {
  description = "Configured recurring amount in the subscription billing currency."
  value       = azurerm_consumption_budget_subscription.this.amount
}

output "notification_count" {
  description = "Number of configured threshold notifications."
  value       = length(var.notifications)
}
