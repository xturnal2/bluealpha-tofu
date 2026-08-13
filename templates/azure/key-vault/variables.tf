variable "subscription_id" {
  description = "Azure subscription ID used by the provider."
  type        = string
  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a UUID."
  }
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID for the vault, or null to use the authenticated tenant."
  type        = string
  default     = null
  validation {
    condition     = var.tenant_id == null || can(regex("^[0-9a-fA-F-]{36}$", var.tenant_id))
    error_message = "tenant_id must be a UUID or null."
  }
}

variable "location" {
  description = "Azure region for the resource group and vault."
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
  description = "Create the vault resource group. Set false to use an existing group."
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Resource group name. Required when create_resource_group is false."
  type        = string
  default     = null
}

variable "vault_name" {
  description = "Globally unique 3-24 character Key Vault name, or null for a generated name."
  type        = string
  default     = null
  validation {
    condition     = var.vault_name == null || can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", var.vault_name))
    error_message = "vault_name must be 3-24 letters, numbers, or hyphens, begin with a letter, and end with a letter or number."
  }
  validation {
    condition     = var.vault_name == null || !strcontains(var.vault_name, "--")
    error_message = "vault_name cannot contain consecutive hyphens."
  }
}

variable "sku_name" {
  description = "Key Vault tier. Premium is required for HSM-backed keys."
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "sku_name must be standard or premium."
  }
}

variable "soft_delete_retention_days" {
  description = "Days deleted vaults and objects remain recoverable."
  type        = number
  default     = 90
  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90 && floor(var.soft_delete_retention_days) == var.soft_delete_retention_days
    error_message = "soft_delete_retention_days must be an integer from 7 through 90."
  }
}

variable "purge_protection_enabled" {
  description = "Prevent purging deleted vaults/objects until retention expires. Once enabled, Azure does not allow disabling it."
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Expose the authenticated public endpoint. Disable when private endpoint and DNS are managed separately."
  type        = bool
  default     = true
}

variable "allowed_ip_cidrs" {
  description = "IPv4 CIDRs allowed through the public endpoint. Empty permits authenticated public access unless public networking is disabled."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for cidr in var.allowed_ip_cidrs : can(cidrnetmask(cidr)) && strcontains(cidr, ".")])
    error_message = "Every allowed_ip_cidrs entry must be a valid IPv4 CIDR."
  }
}

variable "allowed_subnet_ids" {
  description = "Subnet resource IDs allowed through Key Vault service endpoints."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for id in var.allowed_subnet_ids : can(regex("^/subscriptions/.+/subnets/[^/]+$", id))])
    error_message = "Every allowed_subnet_ids entry must be an Azure subnet resource ID."
  }
}

variable "trusted_services_bypass_enabled" {
  description = "Allow designated trusted Azure services to bypass vault network ACLs. RBAC still applies."
  type        = bool
  default     = true
}

variable "enabled_for_deployment" {
  description = "Allow Azure Virtual Machines to retrieve certificates stored as secrets."
  type        = bool
  default     = false
}

variable "enabled_for_disk_encryption" {
  description = "Allow Azure Disk Encryption to retrieve secrets and unwrap keys."
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Allow Azure Resource Manager deployments to retrieve secrets."
  type        = bool
  default     = false
}

variable "role_assignments" {
  description = "Vault-scoped RBAC assignments keyed by a stable label. Default role grants secret read access."
  type = map(object({
    principal_id                     = string
    role                             = optional(string, "Key Vault Secrets User")
    skip_service_principal_aad_check = optional(bool, false)
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
