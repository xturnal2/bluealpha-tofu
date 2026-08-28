locals {
  resource_group_name = coalesce(var.resource_group_name, "${var.project_name}-${var.environment}-monitoring-rg")
  action_group_name   = coalesce(var.action_group_name, "${var.project_name}-${var.environment}-alerts")
  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "azure/monitor-action-group"
  }, var.tags)
}

resource "azurerm_resource_group" "this" {
  count    = var.create_resource_group ? 1 : 0
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_monitor_action_group" "this" {
  name                = local.action_group_name
  resource_group_name = local.resource_group_name
  short_name          = var.short_name
  enabled             = var.enabled
  tags                = local.common_tags

  dynamic "email_receiver" {
    for_each = var.email_receivers
    content {
      name                    = email_receiver.key
      email_address           = email_receiver.value.email_address
      use_common_alert_schema = email_receiver.value.use_common_alert_schema
    }
  }

  dynamic "webhook_receiver" {
    for_each = var.webhook_receivers
    content {
      name                    = webhook_receiver.key
      service_uri             = webhook_receiver.value.service_uri
      use_common_alert_schema = webhook_receiver.value.use_common_alert_schema

      dynamic "aad_auth" {
        for_each = webhook_receiver.value.aad_auth == null ? [] : [webhook_receiver.value.aad_auth]
        content {
          object_id      = aad_auth.value.object_id
          identifier_uri = aad_auth.value.identifier_uri
          tenant_id      = aad_auth.value.tenant_id
        }
      }
    }
  }

  depends_on = [azurerm_resource_group.this]

  lifecycle {
    precondition {
      condition     = var.create_resource_group || var.resource_group_name != null
      error_message = "resource_group_name is required when create_resource_group is false."
    }
    precondition {
      condition     = length(var.email_receivers) + length(var.webhook_receivers) > 0
      error_message = "At least one email or webhook receiver is required."
    }
  }
}
