variable "subscription_id" {
  description = "Azure subscription ID used by the provider."
  type        = string
  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a UUID."
  }
}

variable "location" {
  description = "Azure region for the identity."
  type        = string
  default     = "eastus"
}

variable "project_name" {
  description = "Short project identifier used in names and tags."
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

variable "create_resource_group" {
  description = "Create the identity resource group."
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Existing resource group name when create_resource_group is false."
  type        = string
  default     = null
}

variable "identity_name" {
  description = "User-assigned identity name or null for project-environment-workload."
  type        = string
  default     = null
  validation {
    condition     = var.identity_name == null || can(regex("^[A-Za-z0-9][A-Za-z0-9-_]{2,127}$", var.identity_name))
    error_message = "identity_name must be 3-128 letters, numbers, hyphens, or underscores and start alphanumeric."
  }
}

variable "isolation_scope" {
  description = "Optional identity isolation scope. Regional can limit identity use to the Azure region where supported."
  type        = string
  default     = null
  validation {
    condition     = var.isolation_scope == null || var.isolation_scope == "Regional"
    error_message = "isolation_scope must be null or Regional."
  }
}

variable "federated_credentials" {
  description = "OIDC trust relationships keyed by credential name. Subjects must identify exact external workloads."
  type = map(object({
    issuer    = string
    subject   = string
    audiences = optional(set(string), ["api://AzureADTokenExchange"])
  }))
  default = {}
  validation {
    condition = alltrue([
      for credential in values(var.federated_credentials) :
      can(regex("^https://", credential.issuer)) &&
      length(trimspace(credential.subject)) > 0 &&
      length(credential.audiences) > 0
    ])
    error_message = "Every federated credential requires an HTTPS issuer, non-empty subject, and at least one audience."
  }
}

variable "role_assignments" {
  description = "Azure RBAC assignments for the identity keyed by stable label."
  type = map(object({
    scope             = string
    role              = string
    condition         = optional(string, null)
    condition_version = optional(string, null)
  }))
  default = {}
  validation {
    condition = alltrue([
      for assignment in values(var.role_assignments) :
      startswith(assignment.scope, "/subscriptions/") &&
      length(trimspace(assignment.role)) > 0 &&
      ((assignment.condition == null) == (assignment.condition_version == null))
    ])
    error_message = "Each role assignment requires an Azure scope, role, and both or neither of condition and condition_version."
  }
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
