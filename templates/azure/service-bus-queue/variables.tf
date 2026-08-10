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

variable "namespace_name" {
  description = "Globally unique Service Bus namespace name or null to append a stable random suffix."
  type        = string
  default     = null
  validation {
    condition     = var.namespace_name == null || can(regex("^[a-z][a-z0-9-]{4,48}[a-z0-9]$", var.namespace_name))
    error_message = "namespace_name must be 6-50 lowercase letters, numbers, or hyphens."
  }
}

variable "queue_name" {
  description = "Service Bus queue name."
  type        = string
  default     = "messages"
  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9._~/-]{0,258}[A-Za-z0-9]$", var.queue_name))
    error_message = "queue_name must be 2-260 supported characters without leading or trailing punctuation."
  }
}

variable "sku" {
  description = "Service Bus namespace tier."
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be Basic, Standard, or Premium."
  }
}

variable "premium_messaging_units" {
  description = "Messaging units allocated to a Premium namespace."
  type        = number
  default     = 1
  validation {
    condition     = contains([1, 2, 4, 8, 16], var.premium_messaging_units)
    error_message = "premium_messaging_units must be 1, 2, 4, 8, or 16."
  }
}

variable "premium_messaging_partitions" {
  description = "Partition count for a Premium namespace. This is fixed after creation."
  type        = number
  default     = 1
  validation {
    condition     = contains([1, 2, 4], var.premium_messaging_partitions)
    error_message = "premium_messaging_partitions must be 1, 2, or 4."
  }
}

variable "local_auth_enabled" {
  description = "Enable SAS key authentication. False requires Microsoft Entra ID data-plane roles."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Allow access through the public Service Bus endpoint. Disabling requires separate private endpoints."
  type        = bool
  default     = true
}

variable "allowed_ip_cidrs" {
  description = "Public IPv4 CIDRs allowed by Premium namespace network rules."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for cidr in var.allowed_ip_cidrs : can(cidrnetmask(cidr))])
    error_message = "allowed_ip_cidrs must contain valid IPv4 CIDRs."
  }
}

variable "allowed_subnet_ids" {
  description = "Subnet IDs allowed by Premium namespace network rules. Subnets need the Service Bus service endpoint."
  type        = set(string)
  default     = []
}

variable "trusted_services_allowed" {
  description = "Allow trusted Microsoft services to bypass namespace network rules."
  type        = bool
  default     = false
}

variable "max_size_in_megabytes" {
  description = "Maximum queue storage in MiB. Availability depends on tier and partitioning."
  type        = number
  default     = 1024
  validation {
    condition     = contains([1024, 2048, 3072, 4096, 5120, 10240, 20480, 40960, 81920], var.max_size_in_megabytes)
    error_message = "max_size_in_megabytes must be a supported Service Bus queue size."
  }
}

variable "max_message_size_in_kilobytes" {
  description = "Maximum message size for supported Premium namespaces, or null for the tier default."
  type        = number
  default     = null
  validation {
    condition     = var.max_message_size_in_kilobytes == null || var.max_message_size_in_kilobytes > 0
    error_message = "max_message_size_in_kilobytes must be null or greater than zero."
  }
}

variable "default_message_ttl" {
  description = "Default message time to live as an ISO 8601 duration."
  type        = string
  default     = "P14D"
}

variable "lock_duration" {
  description = "Peek-lock duration as an ISO 8601 duration, from PT5S through PT5M."
  type        = string
  default     = "PT1M"
}

variable "max_delivery_count" {
  description = "Delivery attempts before Service Bus moves a message to the built-in DLQ."
  type        = number
  default     = 10
  validation {
    condition     = var.max_delivery_count >= 1 && floor(var.max_delivery_count) == var.max_delivery_count
    error_message = "max_delivery_count must be a positive integer."
  }
}

variable "dead_lettering_on_message_expiration" {
  description = "Move expired messages to the built-in dead-letter subqueue."
  type        = bool
  default     = true
}

variable "requires_session" {
  description = "Require session IDs for ordered, stateful message processing. Fixed after creation."
  type        = bool
  default     = false
}

variable "requires_duplicate_detection" {
  description = "Discard repeated MessageId values within the detection window. Fixed after creation."
  type        = bool
  default     = false
}

variable "duplicate_detection_history_time_window" {
  description = "Duplicate detection window as an ISO 8601 duration."
  type        = string
  default     = "PT10M"
}

variable "partitioning_enabled" {
  description = "Enable entity partitioning on Standard. Premium partitioning is configured on the namespace."
  type        = bool
  default     = false
}

variable "auto_delete_on_idle" {
  description = "Delete the queue after an idle ISO 8601 duration, or null to retain it."
  type        = string
  default     = null
}

variable "forward_to" {
  description = "Queue or topic name in the same namespace to receive automatically forwarded active messages."
  type        = string
  default     = null
}

variable "forward_dead_lettered_messages_to" {
  description = "Queue or topic name in the same namespace to receive automatically forwarded dead-letter messages."
  type        = string
  default     = null
}

variable "data_plane_role_assignments" {
  description = "Named Microsoft Entra principals granted queue-scoped Service Bus data roles."
  type = map(object({
    principal_id = string
    role         = string
  }))
  default = {}
  validation {
    condition = alltrue([
      for assignment in values(var.data_plane_role_assignments) :
      contains(["Azure Service Bus Data Sender", "Azure Service Bus Data Receiver", "Azure Service Bus Data Owner"], assignment.role)
    ])
    error_message = "role must be an Azure Service Bus Data Sender, Data Receiver, or Data Owner role."
  }
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
