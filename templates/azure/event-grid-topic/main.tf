locals {
  name_prefix         = "${var.project_name}-${var.environment}"
  resource_group_name = coalesce(var.resource_group_name, "${local.name_prefix}-events-rg")
  topic_name          = coalesce(var.topic_name, "${local.name_prefix}-events")

  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "azure-event-grid-topic"
  }, var.tags)
}

resource "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 1 : 0

  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_eventgrid_topic" "this" {
  name                          = local.topic_name
  location                      = var.location
  resource_group_name           = local.resource_group_name
  input_schema                  = var.input_schema
  local_auth_enabled            = var.local_auth_enabled
  public_network_access_enabled = var.public_network_access_enabled
  inbound_ip_rule = [for cidr in sort(tolist(var.allowed_ip_cidrs)) : {
    ip_mask = cidr
    action  = "Allow"
  }]
  tags = local.common_tags

  identity {
    type = "SystemAssigned"
  }

  depends_on = [azurerm_resource_group.this]

  lifecycle {
    precondition {
      condition     = var.create_resource_group || var.resource_group_name != null
      error_message = "resource_group_name is required when create_resource_group is false."
    }
    precondition {
      condition     = var.public_network_access_enabled || length(var.allowed_ip_cidrs) == 0
      error_message = "allowed_ip_cidrs must be empty when public_network_access_enabled is false."
    }
  }
}

resource "azurerm_role_assignment" "publisher" {
  for_each = var.publisher_role_assignments

  scope                            = azurerm_eventgrid_topic.this.id
  role_definition_name             = each.value.role
  principal_id                     = each.value.principal_id
  skip_service_principal_aad_check = each.value.skip_service_principal_aad_check
}

resource "azurerm_eventgrid_event_subscription" "this" {
  for_each = var.event_subscriptions

  name                          = each.key
  scope                         = azurerm_eventgrid_topic.this.id
  event_delivery_schema         = "EventGridSchema"
  included_event_types          = length(each.value.included_event_types) == 0 ? null : sort(tolist(each.value.included_event_types))
  eventhub_endpoint_id          = each.value.endpoint_type == "eventhub" ? each.value.endpoint : null
  service_bus_queue_endpoint_id = each.value.endpoint_type == "service_bus_queue" ? each.value.endpoint : null
  service_bus_topic_endpoint_id = each.value.endpoint_type == "service_bus_topic" ? each.value.endpoint : null

  dynamic "azure_function_endpoint" {
    for_each = each.value.endpoint_type == "azure_function" ? [1] : []
    content {
      function_id = each.value.endpoint
    }
  }

  dynamic "storage_queue_endpoint" {
    for_each = each.value.endpoint_type == "storage_queue" ? [1] : []
    content {
      storage_account_id = each.value.endpoint
      queue_name         = each.value.storage_queue_name
    }
  }

  dynamic "webhook_endpoint" {
    for_each = each.value.endpoint_type == "webhook" ? [1] : []
    content {
      url = each.value.endpoint
    }
  }

  subject_filter {
    subject_begins_with = each.value.subject_begins_with
    subject_ends_with   = each.value.subject_ends_with
    case_sensitive      = each.value.subject_case_sensitive
  }

  retry_policy {
    max_delivery_attempts = each.value.max_delivery_attempts
    event_time_to_live    = each.value.event_time_to_live
  }
}
