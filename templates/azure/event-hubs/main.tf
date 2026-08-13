locals {
  name_prefix         = "${var.project_name}-${var.environment}"
  resource_group_name = coalesce(var.resource_group_name, "${local.name_prefix}-streaming-rg")
  namespace_name      = coalesce(var.namespace_name, "${local.name_prefix}-eh-${random_string.suffix.result}")
  network_restricted  = !var.public_network_access_enabled || length(var.allowed_ip_cidrs) > 0 || length(var.allowed_subnet_ids) > 0

  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "azure-event-hubs"
  }, var.tags)
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "this" {
  count    = var.create_resource_group ? 1 : 0
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_eventhub_namespace" "this" {
  name                          = local.namespace_name
  location                      = var.location
  resource_group_name           = local.resource_group_name
  sku                           = var.sku
  capacity                      = var.capacity
  auto_inflate_enabled          = var.sku == "Standard" ? var.auto_inflate_enabled : false
  maximum_throughput_units      = var.sku == "Standard" && var.auto_inflate_enabled ? var.maximum_throughput_units : null
  local_authentication_enabled  = var.local_authentication_enabled
  public_network_access_enabled = var.public_network_access_enabled
  minimum_tls_version           = "1.2"

  network_rulesets = [{
    default_action                 = local.network_restricted ? "Deny" : "Allow"
    public_network_access_enabled  = var.public_network_access_enabled
    trusted_service_access_enabled = var.trusted_services_allowed
    ip_rule = [for cidr in sort(tolist(var.allowed_ip_cidrs)) : {
      ip_mask = cidr
      action  = "Allow"
    }]
    virtual_network_rule = [for id in sort(tolist(var.allowed_subnet_ids)) : {
      subnet_id                                       = id
      ignore_missing_virtual_network_service_endpoint = false
    }]
  }]

  identity {
    type = "SystemAssigned"
  }

  tags       = local.common_tags
  depends_on = [azurerm_resource_group.this]

  lifecycle {
    precondition {
      condition     = var.create_resource_group || var.resource_group_name != null
      error_message = "resource_group_name is required when create_resource_group is false."
    }
    precondition {
      condition     = var.sku == "Standard" || !var.auto_inflate_enabled
      error_message = "auto_inflate_enabled requires the Standard SKU."
    }
    precondition {
      condition     = var.public_network_access_enabled || (length(var.allowed_ip_cidrs) == 0 && length(var.allowed_subnet_ids) == 0)
      error_message = "IP and subnet rules must be empty when public network access is disabled."
    }
  }
}

resource "azurerm_eventhub" "this" {
  name              = var.eventhub_name
  namespace_id      = azurerm_eventhub_namespace.this.id
  partition_count   = var.partition_count
  message_retention = var.message_retention_days
  status            = "Active"
}

resource "azurerm_eventhub_consumer_group" "this" {
  for_each = var.consumer_groups

  name                = each.key
  namespace_name      = azurerm_eventhub_namespace.this.name
  eventhub_name       = azurerm_eventhub.this.name
  resource_group_name = local.resource_group_name
  user_metadata       = each.value.user_metadata
}

resource "azurerm_role_assignment" "eventhub" {
  for_each = var.role_assignments

  scope                = azurerm_eventhub.this.id
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id
}
