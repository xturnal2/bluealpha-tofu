output "metric_alert_id" {
  description = "Azure resource ID of the metric alert."
  value       = azurerm_monitor_metric_alert.this.id
}
output "metric_alert_name" {
  description = "Name of the metric alert."
  value       = azurerm_monitor_metric_alert.this.name
}
output "resource_group_name" {
  description = "Resource group containing the alert definition."
  value       = local.resource_group_name
}
