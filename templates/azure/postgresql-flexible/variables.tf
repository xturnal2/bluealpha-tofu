variable "subscription_id" {
  description = "Azure subscription ID. Null uses ARM_SUBSCRIPTION_ID from the environment."
  type        = string
  default     = null
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

variable "location" {
  description = "Azure region."
  type        = string
  default     = "eastus"
}

variable "create_resource_group" {
  description = "Create a resource group. Set false to reuse an existing group."
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Existing resource group name or null for a generated name. Required when create_resource_group is false."
  type        = string
  default     = null
}

variable "delegated_subnet_id" {
  description = "ID of a subnet delegated to Microsoft.DBforPostgreSQL/flexibleServers."
  type        = string
}

variable "virtual_network_id" {
  description = "VNet ID linked to the new private DNS zone. Required when create_private_dns_zone is true."
  type        = string
  default     = null
}

variable "create_private_dns_zone" {
  description = "Create and link a private DNS zone for the server."
  type        = bool
  default     = true
}

variable "private_dns_zone_id" {
  description = "Existing PostgreSQL private DNS zone ID. Required when create_private_dns_zone is false."
  type        = string
  default     = null
}

variable "private_dns_zone_name" {
  description = "Name for the private DNS zone created by this stack."
  type        = string
  default     = null
}

variable "server_name" {
  description = "Globally unique server name or null to append a stable random suffix."
  type        = string
  default     = null
  validation {
    condition     = var.server_name == null || can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.server_name))
    error_message = "server_name must be 3-63 lowercase letters, numbers, or hyphens."
  }
}

variable "administrator_login" {
  description = "Local PostgreSQL administrator login."
  type        = string
  default     = "pgadmin"
  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,62}$", var.administrator_login))
    error_message = "administrator_login must start with a letter and contain at most 63 letters, numbers, or underscores."
  }
}

variable "administrator_password" {
  description = "Administrator password. Null generates a password. The value remains in OpenTofu state."
  type        = string
  default     = null
  sensitive   = true
  validation {
    condition     = var.administrator_password == null || length(var.administrator_password) >= 8
    error_message = "administrator_password must contain at least 8 characters."
  }
}

variable "postgresql_version" {
  description = "PostgreSQL major version."
  type        = string
  default     = "16"
  validation {
    condition     = contains(["13", "14", "15", "16", "17"], var.postgresql_version)
    error_message = "postgresql_version must be 13, 14, 15, 16, or 17."
  }
}

variable "sku_name" {
  description = "Flexible Server compute SKU, such as B_Standard_B1ms or GP_Standard_D2s_v3."
  type        = string
  default     = "B_Standard_B1ms"
  validation {
    condition     = can(regex("^(B|GP|MO)_Standard_[A-Za-z0-9_]+$", var.sku_name))
    error_message = "sku_name must be a Burstable, General Purpose, or Memory Optimized Flexible Server SKU."
  }
}

variable "storage_mb" {
  description = "Provisioned storage in MiB."
  type        = number
  default     = 32768
  validation {
    condition     = var.storage_mb >= 32768 && floor(var.storage_mb) == var.storage_mb
    error_message = "storage_mb must be an integer of at least 32768 MiB."
  }
}

variable "auto_grow_enabled" {
  description = "Allow Azure to grow storage automatically before capacity is exhausted."
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Automated backup retention in days."
  type        = number
  default     = 7
  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "backup_retention_days must be from 7 through 35."
  }
}

variable "geo_redundant_backup_enabled" {
  description = "Store geo-redundant backups where the region supports them. This adds cost."
  type        = bool
  default     = false
}

variable "availability_zone" {
  description = "Primary availability zone or null for Azure placement."
  type        = string
  default     = null
}

variable "high_availability_mode" {
  description = "High-availability mode: Disabled, SameZone, or ZoneRedundant."
  type        = string
  default     = "Disabled"
  validation {
    condition     = contains(["Disabled", "SameZone", "ZoneRedundant"], var.high_availability_mode)
    error_message = "high_availability_mode must be Disabled, SameZone, or ZoneRedundant."
  }
}

variable "standby_availability_zone" {
  description = "Standby zone for high availability, or null for Azure placement."
  type        = string
  default     = null
}

variable "database_name" {
  description = "Initial application database name. Set null to create no database."
  type        = string
  default     = "app"
  validation {
    condition     = var.database_name == null || can(regex("^[A-Za-z_][A-Za-z0-9_-]{0,62}$", var.database_name))
    error_message = "database_name must start with a letter or underscore and contain at most 63 valid characters."
  }
}

variable "database_charset" {
  description = "Initial database character set."
  type        = string
  default     = "UTF8"
}

variable "database_collation" {
  description = "Initial database collation."
  type        = string
  default     = "en_US.utf8"
}

variable "server_configurations" {
  description = "PostgreSQL server configuration name-to-value map."
  type        = map(string)
  default     = {}
}

variable "maintenance_window" {
  description = "Optional weekly maintenance window in UTC. day_of_week is 0 (Sunday) through 6."
  type = object({
    day_of_week  = number
    start_hour   = number
    start_minute = optional(number, 0)
  })
  default = null
  validation {
    condition = var.maintenance_window == null || (
      var.maintenance_window.day_of_week >= 0 && var.maintenance_window.day_of_week <= 6 &&
      var.maintenance_window.start_hour >= 0 && var.maintenance_window.start_hour <= 23 &&
      var.maintenance_window.start_minute >= 0 && var.maintenance_window.start_minute <= 59
    )
    error_message = "maintenance_window values must describe a valid UTC weekday and time."
  }
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
