variable "subscription_id" {
  description = "Azure subscription ID used by the provider."
  type        = string
  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a UUID."
  }
}

variable "location" {
  description = "Azure region for the resource group and storage account."
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
  description = "Create the storage resource group. Set false to use an existing group."
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Resource group name. Required when create_resource_group is false."
  type        = string
  default     = null
}

variable "storage_account_name" {
  description = "Globally unique 3-24 character lowercase alphanumeric name, or null for a generated name."
  type        = string
  default     = null
  validation {
    condition     = var.storage_account_name == null || can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must be 3-24 lowercase letters and numbers or null."
  }
}

variable "account_replication_type" {
  description = "Data replication strategy. LRS is cost-conscious; ZRS/GRS/GZRS families add resilience and cost."
  type        = string
  default     = "LRS"
  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "RAGRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "account_replication_type must be LRS, ZRS, GRS, RAGRS, GZRS, or RAGZRS."
  }
}

variable "access_tier" {
  description = "Default blob access tier for new objects."
  type        = string
  default     = "Hot"
  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "access_tier must be Hot or Cool."
  }
}

variable "shared_access_key_enabled" {
  description = "Enable storage account keys and Shared Key authorization. Prefer Entra ID and OAuth."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Expose authenticated public storage endpoints. Disable when private endpoints and DNS are managed separately."
  type        = bool
  default     = true
}

variable "allowed_ip_rules" {
  description = "Public IPv4 addresses/CIDRs admitted when network restrictions are configured."
  type        = set(string)
  default     = []
  validation {
    condition = alltrue([
      for rule in var.allowed_ip_rules :
      strcontains(rule, ".") && (can(cidrnetmask(rule)) || can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", rule)))
    ])
    error_message = "Every allowed_ip_rules entry must be a public IPv4 address or CIDR."
  }
}

variable "allowed_subnet_ids" {
  description = "Subnet resource IDs admitted through Microsoft.Storage service endpoints."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for id in var.allowed_subnet_ids : can(regex("^/subscriptions/.+/subnets/[^/]+$", id))])
    error_message = "Every allowed_subnet_ids entry must be an Azure subnet resource ID."
  }
}

variable "network_bypass_services" {
  description = "Azure services allowed to bypass storage network rules."
  type        = set(string)
  default     = ["Logging", "Metrics", "AzureServices"]
  validation {
    condition     = alltrue([for value in var.network_bypass_services : contains(["Logging", "Metrics", "AzureServices", "None"], value)]) && !(contains(var.network_bypass_services, "None") && length(var.network_bypass_services) > 1)
    error_message = "network_bypass_services may contain Logging, Metrics, and AzureServices, or only None."
  }
}

variable "versioning_enabled" {
  description = "Retain prior blob versions for recovery."
  type        = bool
  default     = true
}

variable "blob_delete_retention_days" {
  description = "Days deleted blobs remain recoverable."
  type        = number
  default     = 30
  validation {
    condition     = var.blob_delete_retention_days >= 1 && var.blob_delete_retention_days <= 365 && floor(var.blob_delete_retention_days) == var.blob_delete_retention_days
    error_message = "blob_delete_retention_days must be an integer from 1 through 365."
  }
}

variable "container_delete_retention_days" {
  description = "Days deleted blob containers remain recoverable."
  type        = number
  default     = 30
  validation {
    condition     = var.container_delete_retention_days >= 1 && var.container_delete_retention_days <= 365 && floor(var.container_delete_retention_days) == var.container_delete_retention_days
    error_message = "container_delete_retention_days must be an integer from 1 through 365."
  }
}

variable "change_feed_enabled" {
  description = "Record blob create, modify, and delete events in the storage change feed."
  type        = bool
  default     = false
}

variable "hierarchical_namespace_enabled" {
  description = "Enable Data Lake Storage Gen2 hierarchical namespace. This choice is replacement-sensitive."
  type        = bool
  default     = false
}

variable "containers" {
  description = "Private blob containers keyed by name. Creating them requires data-plane permission for the provisioning identity."
  type = map(object({
    metadata = optional(map(string), {})
  }))
  default = {}
  validation {
    condition     = alltrue([for name in keys(var.containers) : can(regex("^[a-z0-9](?:[a-z0-9-]{1,61}[a-z0-9])$", name)) && !strcontains(name, "--")])
    error_message = "Container names must be 3-63 lowercase letters, numbers, or single hyphens and start/end alphanumeric."
  }
}

variable "role_assignments" {
  description = "Storage-account scoped RBAC assignments keyed by stable label. Default role grants blob read access."
  type = map(object({
    principal_id                     = string
    role                             = optional(string, "Storage Blob Data Reader")
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
