locals {
  name_prefix         = "${var.project_name}-${var.environment}"
  resource_group_name = coalesce(var.resource_group_name, "${local.name_prefix}-identity-rg")
  identity_name       = coalesce(var.identity_name, "${local.name_prefix}-workload")

  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "azure-managed-identity"
  }, var.tags)
}

resource "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 1 : 0

  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_user_assigned_identity" "this" {
  name                = local.identity_name
  location            = var.location
  resource_group_name = local.resource_group_name
  isolation_scope     = var.isolation_scope
  tags                = local.common_tags

  depends_on = [azurerm_resource_group.this]

  lifecycle {
    precondition {
      condition     = var.create_resource_group || var.resource_group_name != null
      error_message = "resource_group_name is required when create_resource_group is false."
    }
  }
}

resource "azurerm_federated_identity_credential" "this" {
  for_each = var.federated_credentials

  name                      = each.key
  user_assigned_identity_id = azurerm_user_assigned_identity.this.id
  issuer                    = trimsuffix(each.value.issuer, "/")
  subject                   = each.value.subject
  audience                  = sort(tolist(each.value.audiences))
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = azurerm_user_assigned_identity.this.principal_id
  principal_type       = "ServicePrincipal"
  condition            = each.value.condition
  condition_version    = each.value.condition_version
}
