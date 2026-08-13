variable "subscription_id" {
  description = "Azure subscription ID used by the provider."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a UUID."
  }
}

variable "location" {
  description = "Azure region for the workspace."
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
  description = "Create the workspace resource group."
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Existing resource group name when create_resource_group is false."
  type        = string
  default     = null
}

variable "workspace_name" {
  description = "Globally unique workspace name, or null for a generated name."
  type        = string
  default     = null

  validation {
    condition     = var.workspace_name == null || can(regex("^[A-Za-z0-9][A-Za-z0-9-]{2,61}[A-Za-z0-9]$", var.workspace_name))
    error_message = "workspace_name must be 4-63 letters, numbers, or hyphens and start and end alphanumeric."
  }
}

variable "sku" {
  description = "PerGB2018 for usage billing or CapacityReservation for a daily commitment tier."
  type        = string
  default     = "PerGB2018"

  validation {
    condition     = contains(["PerGB2018", "CapacityReservation"], var.sku)
    error_message = "sku must be PerGB2018 or CapacityReservation."
  }
}

variable "retention_in_days" {
  description = "Interactive workspace retention in days."
  type        = number
  default     = 30

  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730 && floor(var.retention_in_days) == var.retention_in_days
    error_message = "retention_in_days must be an integer from 30 through 730."
  }
}

variable "daily_quota_gb" {
  description = "Daily ingestion cap in GB. Use -1 only to explicitly remove the cap."
  type        = number
  default     = 1

  validation {
    condition     = var.daily_quota_gb == -1 || (var.daily_quota_gb >= 0.023 && var.daily_quota_gb <= 5000)
    error_message = "daily_quota_gb must be -1 or between 0.023 and 5000."
  }
}

variable "reservation_capacity_in_gb_per_day" {
  description = "CapacityReservation daily commitment. Must be null for PerGB2018."
  type        = number
  default     = null

  validation {
    condition = var.reservation_capacity_in_gb_per_day == null || contains([
      100, 200, 300, 400, 500, 1000, 2000, 5000
    ], var.reservation_capacity_in_gb_per_day)
    error_message = "reservation_capacity_in_gb_per_day must be a supported commitment tier."
  }
}

variable "local_authentication_enabled" {
  description = "Enable workspace shared-key authentication. Prefer Entra ID and Azure RBAC."
  type        = bool
  default     = false
}

variable "internet_ingestion_enabled" {
  description = "Allow authenticated ingestion through the public endpoint. Disable only when private ingestion is configured separately."
  type        = bool
  default     = true
}

variable "internet_query_enabled" {
  description = "Allow authenticated queries through the public endpoint. Disable only when private query access is configured separately."
  type        = bool
  default     = true
}

variable "immediate_data_purge_on_30_days_enabled" {
  description = "Immediately purge data at 30 days instead of retaining it for potential recovery."
  type        = bool
  default     = false
}

variable "role_assignments" {
  description = "Workspace-scoped Azure RBAC assignments keyed by stable label."
  type = map(object({
    principal_id   = string
    role           = string
    principal_type = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for assignment in values(var.role_assignments) :
      length(trimspace(assignment.principal_id)) > 0 &&
      length(trimspace(assignment.role)) > 0 &&
      (assignment.principal_type == null || contains(["Group", "ServicePrincipal", "User"], assignment.principal_type))
    ])
    error_message = "Each role assignment requires a principal ID and role; principal_type may be Group, ServicePrincipal, User, or null."
  }
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
