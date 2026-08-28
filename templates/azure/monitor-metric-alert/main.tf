locals {
  resource_group_name = coalesce(var.resource_group_name, "${var.project_name}-${var.environment}-monitoring-rg")
  alert_name          = coalesce(var.alert_name, "${var.project_name}-${var.environment}-metric-alert")
  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "azure/monitor-metric-alert"
  }, var.tags)
}

resource "azurerm_resource_group" "this" {
  count    = var.create_resource_group ? 1 : 0
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_monitor_metric_alert" "this" {
  name                     = local.alert_name
  resource_group_name      = local.resource_group_name
  scopes                   = var.scopes
  description              = var.description
  severity                 = var.severity
  enabled                  = var.enabled
  auto_mitigate            = var.auto_mitigate
  frequency                = var.frequency
  window_size              = var.window_size
  target_resource_type     = var.target_resource_type
  target_resource_location = var.target_resource_location
  tags                     = local.common_tags

  dynamic "criteria" {
    for_each = var.criteria
    content {
      metric_namespace       = criteria.value.metric_namespace
      metric_name            = criteria.value.metric_name
      aggregation            = criteria.value.aggregation
      operator               = criteria.value.operator
      threshold              = criteria.value.threshold
      skip_metric_validation = criteria.value.skip_metric_validation

      dynamic "dimension" {
        for_each = criteria.value.dimensions
        content {
          name     = dimension.key
          operator = dimension.value.operator
          values   = sort(tolist(dimension.value.values))
        }
      }
    }
  }

  dynamic "action" {
    for_each = var.action_groups
    content {
      action_group_id    = action.key
      webhook_properties = action.value.webhook_properties
    }
  }

  depends_on = [azurerm_resource_group.this]

  lifecycle {
    precondition {
      condition     = var.create_resource_group || var.resource_group_name != null
      error_message = "resource_group_name is required when create_resource_group is false."
    }
    precondition {
      condition     = length(var.scopes) == 1 || (var.target_resource_type != null && var.target_resource_location != null)
      error_message = "Multiple scopes require target_resource_type and target_resource_location."
    }
  }
}
