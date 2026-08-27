locals {
  definition_scope  = coalesce(var.definition_scope, "/subscriptions/${var.subscription_id}")
  assignable_scopes = var.assignable_scopes == null ? [local.definition_scope] : var.assignable_scopes
  role_name         = coalesce(var.role_name, "${var.project_name}-${var.environment}-operator")
}

resource "azurerm_role_definition" "this" {
  name        = local.role_name
  scope       = local.definition_scope
  description = var.description

  assignable_scopes = sort(tolist(local.assignable_scopes))

  permissions {
    actions          = sort(tolist(var.actions))
    not_actions      = sort(tolist(var.not_actions))
    data_actions     = var.data_actions
    not_data_actions = var.not_data_actions
  }

  lifecycle {
    precondition {
      condition     = contains(local.assignable_scopes, local.definition_scope)
      error_message = "assignable_scopes must include definition_scope."
    }
    precondition {
      condition     = alltrue([for scope in local.assignable_scopes : startswith(scope, local.definition_scope)])
      error_message = "Every assignable scope must equal or be below definition_scope."
    }
    precondition {
      condition     = length(var.actions) + length(var.data_actions) > 0
      error_message = "At least one management-plane action or data action is required."
    }
  }
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  scope                            = coalesce(each.value.scope, local.definition_scope)
  role_definition_id               = azurerm_role_definition.this.role_definition_resource_id
  principal_id                     = each.value.principal_id
  principal_type                   = each.value.principal_type
  condition                        = each.value.condition
  condition_version                = each.value.condition_version
  skip_service_principal_aad_check = each.value.skip_service_principal_aad_check

  lifecycle {
    precondition {
      condition     = contains(local.assignable_scopes, coalesce(each.value.scope, local.definition_scope))
      error_message = "Each assignment scope must be listed exactly in assignable_scopes."
    }
  }
}
