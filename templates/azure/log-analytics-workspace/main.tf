locals {
  name_prefix         = "${var.project_name}-${var.environment}"
  resource_group_name = coalesce(var.resource_group_name, "${local.name_prefix}-observability-rg")
  workspace_name      = coalesce(var.workspace_name, "${local.name_prefix}-logs-${random_string.suffix.result}")

  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "azure/log-analytics-workspace"
  }, var.tags)
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 1 : 0

  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = local.workspace_name
  location            = var.location
  resource_group_name = local.resource_group_name

  sku                                     = var.sku
  retention_in_days                       = var.retention_in_days
  daily_quota_gb                          = var.daily_quota_gb
  reservation_capacity_in_gb_per_day      = var.sku == "CapacityReservation" ? var.reservation_capacity_in_gb_per_day : null
  local_authentication_enabled            = var.local_authentication_enabled
  internet_ingestion_enabled              = var.internet_ingestion_enabled
  internet_query_enabled                  = var.internet_query_enabled
  immediate_data_purge_on_30_days_enabled = var.immediate_data_purge_on_30_days_enabled
  tags                                    = local.common_tags

  depends_on = [azurerm_resource_group.this]

  lifecycle {
    precondition {
      condition     = var.create_resource_group || var.resource_group_name != null
      error_message = "resource_group_name is required when create_resource_group is false."
    }
    precondition {
      condition     = (var.sku == "CapacityReservation") == (var.reservation_capacity_in_gb_per_day != null)
      error_message = "reservation_capacity_in_gb_per_day must be set only for the CapacityReservation SKU."
    }
    precondition {
      condition     = !var.immediate_data_purge_on_30_days_enabled || var.retention_in_days == 30
      error_message = "immediate_data_purge_on_30_days_enabled requires retention_in_days to be 30."
    }
  }
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  scope                = azurerm_log_analytics_workspace.this.id
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id
  principal_type       = each.value.principal_type
}
