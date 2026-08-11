data "azurerm_client_config" "current" {}

locals {
  name_prefix         = "${var.project_name}-${var.environment}"
  resource_group_name = coalesce(var.resource_group_name, "${local.name_prefix}-security-rg")
  generated_name      = "kv-${substr(replace(var.project_name, "-", ""), 0, 8)}-${substr(replace(var.environment, "-", ""), 0, 5)}-${random_string.suffix.result}"
  vault_name          = coalesce(var.vault_name, local.generated_name)
  tenant_id           = coalesce(var.tenant_id, data.azurerm_client_config.current.tenant_id)
  network_restricted  = !var.public_network_access_enabled || length(var.allowed_ip_cidrs) > 0 || length(var.allowed_subnet_ids) > 0

  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "azure-key-vault"
  }, var.tags)
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 1 : 0

  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_key_vault" "this" {
  name                            = local.vault_name
  location                        = var.location
  resource_group_name             = local.resource_group_name
  tenant_id                       = local.tenant_id
  sku_name                        = var.sku_name
  rbac_authorization_enabled      = true
  soft_delete_retention_days      = var.soft_delete_retention_days
  purge_protection_enabled        = var.purge_protection_enabled
  public_network_access_enabled   = var.public_network_access_enabled
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  tags                            = local.common_tags

  network_acls {
    bypass                     = var.trusted_services_bypass_enabled ? "AzureServices" : "None"
    default_action             = local.network_restricted ? "Deny" : "Allow"
    ip_rules                   = sort(tolist(var.allowed_ip_cidrs))
    virtual_network_subnet_ids = sort(tolist(var.allowed_subnet_ids))
  }

  depends_on = [azurerm_resource_group.this]

  lifecycle {
    precondition {
      condition     = var.create_resource_group || var.resource_group_name != null
      error_message = "resource_group_name is required when create_resource_group is false."
    }
  }
}

resource "azurerm_role_assignment" "vault" {
  for_each = var.role_assignments

  scope                            = azurerm_key_vault.this.id
  role_definition_name             = each.value.role
  principal_id                     = each.value.principal_id
  skip_service_principal_aad_check = each.value.skip_service_principal_aad_check
}
