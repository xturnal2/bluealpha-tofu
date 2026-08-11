variable "subscription_id" {
  description = "Azure subscription ID used by the provider."
  type        = string
  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a UUID."
  }
}

variable "location" {
  description = "Azure region for the resource group and registry."
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
  description = "Create the registry resource group. Set false to use an existing group."
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Resource group name. Required when create_resource_group is false."
  type        = string
  default     = null
}

variable "registry_name" {
  description = "Globally unique 5-50 character alphanumeric registry name, or null for a generated name."
  type        = string
  default     = null
  validation {
    condition     = var.registry_name == null || can(regex("^[A-Za-z0-9]{5,50}$", var.registry_name))
    error_message = "registry_name must be 5-50 alphanumeric characters or null."
  }
}

variable "sku" {
  description = "Container Registry service tier. Premium is required for network rules, geo-replication, and advanced controls."
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be Basic, Standard, or Premium."
  }
}

variable "admin_enabled" {
  description = "Enable the shared registry admin account. Prefer Entra ID and managed identities."
  type        = bool
  default     = false
}

variable "anonymous_pull_enabled" {
  description = "Allow unauthenticated image pulls. Supported on Standard and Premium only."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Expose the authenticated registry endpoint publicly. Disable when private endpoints are managed separately."
  type        = bool
  default     = true
}

variable "allowed_ip_cidrs" {
  description = "Public IPv4 CIDRs allowed by Premium registry network rules. Empty leaves the authenticated public endpoint unrestricted."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for cidr in var.allowed_ip_cidrs : can(cidrnetmask(cidr))])
    error_message = "Every allowed_ip_cidrs entry must be a valid CIDR."
  }
}

variable "trusted_services_allowed" {
  description = "Allow trusted Azure services to bypass registry network restrictions."
  type        = bool
  default     = true
}

variable "retention_policy_in_days" {
  description = "Premium-only retention period for untagged manifests."
  type        = number
  default     = 7
  validation {
    condition     = var.retention_policy_in_days >= 0 && var.retention_policy_in_days <= 365 && floor(var.retention_policy_in_days) == var.retention_policy_in_days
    error_message = "retention_policy_in_days must be an integer from 0 through 365."
  }
}

variable "zone_redundancy_enabled" {
  description = "Enable Premium registry zone redundancy where supported."
  type        = bool
  default     = false
}

variable "export_policy_enabled" {
  description = "Allow image export from a Premium registry. Disable only with public network access disabled."
  type        = bool
  default     = true
}

variable "georeplications" {
  description = "Premium geo-replica regions keyed by a stable label. The primary location must not be repeated."
  type = map(object({
    location                = string
    zone_redundancy_enabled = optional(bool, false)
    tags                    = optional(map(string), {})
  }))
  default = {}
}

variable "role_assignments" {
  description = "Registry data-plane RBAC assignments keyed by a stable label. Common roles are AcrPull and AcrPush."
  type = map(object({
    principal_id = string
    role         = optional(string, "AcrPull")
  }))
  default = {}
  validation {
    condition     = alltrue([for assignment in values(var.role_assignments) : length(trimspace(assignment.principal_id)) > 0 && length(trimspace(assignment.role)) > 0])
    error_message = "Every role assignment requires a principal_id and non-empty role."
  }
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
