locals {
  name_prefix         = "${var.project_name}-${var.environment}"
  resource_group_name = coalesce(var.resource_group_name, "${local.name_prefix}-storage-rg")
  generated_name      = substr("${replace(var.project_name, "-", "")}${replace(var.environment, "-", "")}${random_string.suffix.result}", 0, 24)
  storage_name        = coalesce(var.storage_account_name, local.generated_name)
  network_restricted  = !var.public_network_access_enabled || length(var.allowed_ip_rules) > 0 || length(var.allowed_subnet_ids) > 0

  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "azure-storage-account"
  }, var.tags)
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 1 : 0

  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_storage_account" "this" {
  name                = local.storage_name
  resource_group_name = local.resource_group_name
  location            = var.location

  account_kind                      = "StorageV2"
  account_tier                      = "Standard"
  account_replication_type          = var.account_replication_type
  access_tier                       = var.access_tier
  min_tls_version                   = "TLS1_2"
  https_traffic_only_enabled        = true
  allow_nested_items_to_be_public   = false
  shared_access_key_enabled         = var.shared_access_key_enabled
  default_to_oauth_authentication   = true
  public_network_access_enabled     = var.public_network_access_enabled
  cross_tenant_replication_enabled  = false
  infrastructure_encryption_enabled = true
  is_hns_enabled                    = var.hierarchical_namespace_enabled
  local_user_enabled                = false

  identity {
    type = "SystemAssigned"
  }

  blob_properties {
    versioning_enabled  = var.versioning_enabled
    change_feed_enabled = var.change_feed_enabled

    delete_retention_policy {
      days = var.blob_delete_retention_days
    }

    container_delete_retention_policy {
      days = var.container_delete_retention_days
    }
  }

  network_rules {
    default_action             = local.network_restricted ? "Deny" : "Allow"
    bypass                     = sort(tolist(var.network_bypass_services))
    ip_rules                   = sort(tolist(var.allowed_ip_rules))
    virtual_network_subnet_ids = sort(tolist(var.allowed_subnet_ids))
  }

  tags = local.common_tags

  depends_on = [azurerm_resource_group.this]

  lifecycle {
    precondition {
      condition     = var.create_resource_group || var.resource_group_name != null
      error_message = "resource_group_name is required when create_resource_group is false."
    }
    precondition {
      condition     = var.public_network_access_enabled || (length(var.allowed_ip_rules) == 0 && length(var.allowed_subnet_ids) == 0)
      error_message = "IP and subnet rules must be empty when public_network_access_enabled is false; use private endpoints instead."
    }
  }
}

resource "azurerm_storage_container" "this" {
  for_each = var.containers

  name                  = each.key
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
  metadata              = each.value.metadata
}

resource "azurerm_role_assignment" "storage" {
  for_each = var.role_assignments

  scope                            = azurerm_storage_account.this.id
  role_definition_name             = each.value.role
  principal_id                     = each.value.principal_id
  skip_service_principal_aad_check = each.value.skip_service_principal_aad_check
}
