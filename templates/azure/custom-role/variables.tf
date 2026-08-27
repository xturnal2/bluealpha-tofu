variable "subscription_id" {
  description = "Azure subscription ID used by the provider and default role scope."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a UUID."
  }
}

variable "project_name" {
  description = "Short project identifier used in the default role name."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,18}[a-z0-9]$", var.project_name))
    error_message = "project_name must be 3-20 lowercase letters, numbers, or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,14}[a-z0-9]$", var.environment))
    error_message = "environment must be 3-16 lowercase letters, numbers, or hyphens."
  }
}

variable "role_name" {
  description = "Display name for the custom role, or null for project-environment-operator."
  type        = string
  default     = null

  validation {
    condition     = var.role_name == null || (length(trimspace(var.role_name)) >= 3 && length(var.role_name) <= 128)
    error_message = "role_name must be 3-128 non-whitespace characters when set."
  }
}

variable "description" {
  description = "Human-readable purpose and ownership of the custom role."
  type        = string
  default     = "Least-privilege custom role managed by OpenTofu"

  validation {
    condition     = length(var.description) <= 1024
    error_message = "description must not exceed 1024 characters."
  }
}

variable "definition_scope" {
  description = "Management group, subscription, resource group, or resource scope where the role definition is stored; null uses the subscription."
  type        = string
  default     = null

  validation {
    condition     = var.definition_scope == null || startswith(var.definition_scope, "/subscriptions/") || startswith(var.definition_scope, "/providers/Microsoft.Management/managementGroups/")
    error_message = "definition_scope must be an Azure subscription/resource scope or management-group scope."
  }
}

variable "assignable_scopes" {
  description = "Exact scopes where the role may be assigned; null uses only definition_scope."
  type        = set(string)
  default     = null

  validation {
    condition     = var.assignable_scopes == null || (length(var.assignable_scopes) > 0 && alltrue([for scope in var.assignable_scopes : startswith(scope, "/")]))
    error_message = "assignable_scopes must be null or a non-empty set of Azure resource IDs."
  }
}

variable "actions" {
  description = "Allowed management-plane operations, such as Microsoft.Resources/subscriptions/resourceGroups/read."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for action in var.actions : length(trimspace(action)) > 0 && strcontains(action, "/")])
    error_message = "Every action must be a non-empty Azure provider operation."
  }
}

variable "not_actions" {
  description = "Management-plane operations removed from broad actions. This is not a deny rule."
  type        = set(string)
  default     = []
}

variable "data_actions" {
  description = "Allowed data-plane operations. Use only when the target resource provider supports Azure RBAC data actions."
  type        = set(string)
  default     = []
}

variable "not_data_actions" {
  description = "Data-plane operations removed from broad data_actions. This is not a deny rule."
  type        = set(string)
  default     = []
}

variable "role_assignments" {
  description = "Optional assignments of the custom role, keyed by stable label. Assignment scopes must appear exactly in assignable_scopes."
  type = map(object({
    principal_id                     = string
    principal_type                   = optional(string, null)
    scope                            = optional(string, null)
    condition                        = optional(string, null)
    condition_version                = optional(string, null)
    skip_service_principal_aad_check = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for assignment in values(var.role_assignments) :
      can(regex("^[0-9a-fA-F-]{36}$", assignment.principal_id)) &&
      (assignment.principal_type == null || contains(["Group", "ServicePrincipal", "User"], assignment.principal_type)) &&
      ((assignment.condition == null) == (assignment.condition_version == null))
    ])
    error_message = "Assignments require a principal UUID, an optional supported principal type, and both or neither condition fields."
  }
}
