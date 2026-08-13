variable "subscription_id" {
  description = "Azure subscription ID used by the provider."
  type        = string
  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a UUID."
  }
}

variable "location" {
  description = "Azure region for Event Hubs."
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
  description = "Create the Event Hubs resource group."
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Existing resource group name when create_resource_group is false."
  type        = string
  default     = null
}

variable "namespace_name" {
  description = "Globally unique Event Hubs namespace name, or null for a generated name."
  type        = string
  default     = null
  validation {
    condition     = var.namespace_name == null || can(regex("^[A-Za-z][A-Za-z0-9-]{4,48}[A-Za-z0-9]$", var.namespace_name))
    error_message = "namespace_name must be 6-50 letters, numbers, or hyphens, start with a letter, and end alphanumeric."
  }
}

variable "eventhub_name" {
  description = "Event Hub entity name."
  type        = string
  default     = "events"
  validation {
    condition     = can(regex("^[A-Za-z0-9._-]{1,256}$", var.eventhub_name))
    error_message = "eventhub_name must be 1-256 letters, numbers, periods, underscores, or hyphens."
  }
}

variable "sku" {
  description = "Namespace tier. Standard is the default; Premium changes capacity semantics and cost."
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be Basic, Standard, or Premium."
  }
}

variable "capacity" {
  description = "Standard throughput units or Premium processing units."
  type        = number
  default     = 1
  validation {
    condition     = var.capacity >= 1 && floor(var.capacity) == var.capacity
    error_message = "capacity must be a positive integer."
  }
}

variable "auto_inflate_enabled" {
  description = "Allow a Standard namespace to increase throughput units automatically."
  type        = bool
  default     = false
}

variable "maximum_throughput_units" {
  description = "Maximum Standard throughput units when auto-inflate is enabled."
  type        = number
  default     = 4
  validation {
    condition     = var.maximum_throughput_units >= 1 && var.maximum_throughput_units <= 40 && floor(var.maximum_throughput_units) == var.maximum_throughput_units
    error_message = "maximum_throughput_units must be an integer from 1 through 40."
  }
}

variable "partition_count" {
  description = "Event Hub partition count; choose for peak parallelism because reduction is not supported."
  type        = number
  default     = 4
  validation {
    condition     = var.partition_count >= 1 && var.partition_count <= 32 && floor(var.partition_count) == var.partition_count
    error_message = "partition_count must be an integer from 1 through 32."
  }
}

variable "message_retention_days" {
  description = "Days events remain available to consumers."
  type        = number
  default     = 1
  validation {
    condition     = var.message_retention_days >= 1 && var.message_retention_days <= 90 && floor(var.message_retention_days) == var.message_retention_days
    error_message = "message_retention_days must be an integer from 1 through 90."
  }
}

variable "local_authentication_enabled" {
  description = "Enable SAS connection-string authentication. Prefer Entra ID and managed identities."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Expose authenticated public endpoints. Disable when private endpoints are managed separately."
  type        = bool
  default     = true
}

variable "allowed_ip_cidrs" {
  description = "IPv4 CIDRs allowed through namespace network rules. Empty leaves authenticated public access unrestricted."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for cidr in var.allowed_ip_cidrs : can(cidrnetmask(cidr)) && strcontains(cidr, ".")])
    error_message = "Every allowed_ip_cidrs entry must be a valid IPv4 CIDR."
  }
}

variable "allowed_subnet_ids" {
  description = "Subnet IDs allowed through Microsoft.EventHub service endpoints."
  type        = set(string)
  default     = []
}

variable "trusted_services_allowed" {
  description = "Allow trusted Microsoft services through namespace network rules."
  type        = bool
  default     = true
}

variable "consumer_groups" {
  description = "Consumer groups keyed by name with optional operational metadata."
  type = map(object({
    user_metadata = optional(string, null)
  }))
  default = {
    application = {}
  }
}

variable "role_assignments" {
  description = "Event Hub scoped RBAC assignments keyed by label. Common roles are Azure Event Hubs Data Sender and Data Receiver."
  type = map(object({
    principal_id = string
    role         = string
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
