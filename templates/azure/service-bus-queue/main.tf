locals {
  name_prefix         = "${var.project_name}-${var.environment}"
  resource_group_name = coalesce(var.resource_group_name, "${local.name_prefix}-messaging-rg")
  namespace_name      = coalesce(var.namespace_name, "${local.name_prefix}-sb-${random_string.suffix.result}")
  network_rules_set   = length(var.allowed_ip_cidrs) > 0 || length(var.allowed_subnet_ids) > 0

  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "azure-service-bus-queue"
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

resource "azurerm_servicebus_namespace" "this" {
  name                          = local.namespace_name
  location                      = var.location
  resource_group_name           = local.resource_group_name
  sku                           = var.sku
  capacity                      = var.sku == "Premium" ? var.premium_messaging_units : 0
  premium_messaging_partitions  = var.sku == "Premium" ? var.premium_messaging_partitions : 0
  local_auth_enabled            = var.local_auth_enabled
  minimum_tls_version           = "1.2"
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = local.common_tags

  identity {
    type = "SystemAssigned"
  }

  dynamic "network_rule_set" {
    for_each = var.sku == "Premium" ? [1] : []
    content {
      default_action                = local.network_rules_set ? "Deny" : "Allow"
      public_network_access_enabled = var.public_network_access_enabled
      trusted_services_allowed      = var.trusted_services_allowed
      ip_rules                      = sort(tolist(var.allowed_ip_cidrs))

      dynamic "network_rules" {
        for_each = var.allowed_subnet_ids
        content {
          subnet_id                            = network_rules.value
          ignore_missing_vnet_service_endpoint = false
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
      condition     = var.sku == "Premium" || !local.network_rules_set
      error_message = "Namespace IP/subnet network rules require the Premium tier."
    }
    precondition {
      condition     = var.sku == "Premium" || !var.trusted_services_allowed
      error_message = "trusted_services_allowed requires the Premium tier."
    }
    precondition {
      condition     = var.sku != "Premium" || var.premium_messaging_units % var.premium_messaging_partitions == 0
      error_message = "Premium messaging units must be evenly divisible across namespace partitions."
    }
  }
}

resource "azurerm_servicebus_queue" "this" {
  name                                    = var.queue_name
  namespace_id                            = azurerm_servicebus_namespace.this.id
  status                                  = "Active"
  auto_delete_on_idle                     = var.auto_delete_on_idle
  batched_operations_enabled              = true
  dead_lettering_on_message_expiration    = var.dead_lettering_on_message_expiration
  default_message_ttl                     = var.default_message_ttl
  duplicate_detection_history_time_window = var.duplicate_detection_history_time_window
  express_enabled                         = false
  forward_dead_lettered_messages_to       = var.forward_dead_lettered_messages_to
  forward_to                              = var.forward_to
  lock_duration                           = var.lock_duration
  max_delivery_count                      = var.max_delivery_count
  max_message_size_in_kilobytes           = var.max_message_size_in_kilobytes
  max_size_in_megabytes                   = var.max_size_in_megabytes
  partitioning_enabled                    = var.partitioning_enabled
  requires_duplicate_detection            = var.requires_duplicate_detection
  requires_session                        = var.requires_session

  lifecycle {
    precondition {
      condition     = var.sku != "Basic" || (!var.requires_duplicate_detection && !var.requires_session && var.forward_to == null && var.forward_dead_lettered_messages_to == null)
      error_message = "Duplicate detection, sessions, and forwarding require Standard or Premium."
    }
    precondition {
      condition     = var.partitioning_enabled ? var.sku == "Standard" : true
      error_message = "partitioning_enabled is for Standard; use premium_messaging_partitions for Premium."
    }
    precondition {
      condition     = var.max_message_size_in_kilobytes == null || var.sku == "Premium"
      error_message = "Custom max_message_size_in_kilobytes requires the Premium tier."
    }
    precondition {
      condition     = var.max_size_in_megabytes <= 5120 || var.sku == "Premium"
      error_message = "Queue sizes above 5120 MiB require the Premium tier."
    }
  }
}

resource "azurerm_role_assignment" "data_plane" {
  for_each = var.data_plane_role_assignments

  scope                = azurerm_servicebus_queue.this.id
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id
}
