locals {
  name_prefix         = "${var.project_name}-${var.environment}"
  resource_group_name = coalesce(var.resource_group_name, "${local.name_prefix}-registry-rg")
  generated_name      = substr("${replace(var.project_name, "-", "")}${replace(var.environment, "-", "")}${random_string.suffix.result}", 0, 50)
  registry_name       = coalesce(var.registry_name, local.generated_name)

  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "azure-container-registry"
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

resource "azurerm_container_registry" "this" {
  name                          = local.registry_name
  resource_group_name           = local.resource_group_name
  location                      = var.location
  sku                           = var.sku
  admin_enabled                 = var.admin_enabled
  anonymous_pull_enabled        = var.sku == "Basic" ? null : var.anonymous_pull_enabled
  public_network_access_enabled = var.public_network_access_enabled
  network_rule_bypass_option    = var.trusted_services_allowed ? "AzureServices" : "None"
  retention_policy_in_days      = var.sku == "Premium" ? var.retention_policy_in_days : null
  zone_redundancy_enabled       = var.sku == "Premium" ? var.zone_redundancy_enabled : null
  export_policy_enabled         = var.sku == "Premium" ? var.export_policy_enabled : null
  tags                          = local.common_tags

  identity {
    type = "SystemAssigned"
  }

  dynamic "network_rule_set" {
    for_each = var.sku == "Premium" && length(var.allowed_ip_cidrs) > 0 ? [1] : []
    content {
      default_action = "Deny"

      dynamic "ip_rule" {
        for_each = var.allowed_ip_cidrs
        content {
          action   = "Allow"
          ip_range = ip_rule.value
        }
      }
    }
  }

  dynamic "georeplications" {
    for_each = var.georeplications
    content {
      location                  = georeplications.value.location
      zone_redundancy_enabled   = georeplications.value.zone_redundancy_enabled
      regional_endpoint_enabled = true
      tags                      = merge(local.common_tags, georeplications.value.tags)
    }
  }

  depends_on = [azurerm_resource_group.this]

  lifecycle {
    precondition {
      condition     = var.create_resource_group || var.resource_group_name != null
      error_message = "resource_group_name is required when create_resource_group is false."
    }
    precondition {
      condition     = var.sku == "Premium" || length(var.allowed_ip_cidrs) == 0
      error_message = "allowed_ip_cidrs requires the Premium SKU."
    }
    precondition {
      condition     = var.sku == "Premium" || length(var.georeplications) == 0
      error_message = "georeplications requires the Premium SKU."
    }
    precondition {
      condition     = var.sku != "Basic" || !var.anonymous_pull_enabled
      error_message = "anonymous_pull_enabled requires Standard or Premium."
    }
    precondition {
      condition     = alltrue([for replica in values(var.georeplications) : lower(replica.location) != lower(var.location)])
      error_message = "georeplications must not repeat the primary location."
    }
    precondition {
      condition     = var.export_policy_enabled || !var.public_network_access_enabled
      error_message = "Disabling export_policy_enabled requires public_network_access_enabled to be false."
    }
  }
}

resource "azurerm_role_assignment" "registry" {
  for_each = var.role_assignments

  scope                = azurerm_container_registry.this.id
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id
}
