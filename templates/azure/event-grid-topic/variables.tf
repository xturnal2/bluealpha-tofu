variable "subscription_id" {
  description = "Azure subscription ID used by the provider."
  type        = string
  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a UUID."
  }
}

variable "location" {
  description = "Azure region for the resource group and Event Grid topic."
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
  description = "Create the topic resource group. Set false to use an existing group."
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Resource group name. Required when create_resource_group is false."
  type        = string
  default     = null
}

variable "topic_name" {
  description = "Event Grid custom topic name, or null for project-environment-events."
  type        = string
  default     = null
  validation {
    condition     = var.topic_name == null || can(regex("^[A-Za-z0-9-]{3,50}$", var.topic_name))
    error_message = "topic_name must be 3-50 letters, numbers, or hyphens."
  }
}

variable "input_schema" {
  description = "Schema publishers use for events submitted to the topic."
  type        = string
  default     = "EventGridSchema"
  validation {
    condition     = contains(["EventGridSchema", "CloudEventSchemaV1_0", "CustomEventSchema"], var.input_schema)
    error_message = "input_schema must be EventGridSchema, CloudEventSchemaV1_0, or CustomEventSchema."
  }
}

variable "local_auth_enabled" {
  description = "Enable topic access keys. Keep false to require Microsoft Entra authentication."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Expose the authenticated topic endpoint publicly. Disable when private endpoints are managed separately."
  type        = bool
  default     = true
}

variable "allowed_ip_cidrs" {
  description = "IPv4 CIDRs allowed to publish through the public endpoint. Empty applies no topic IP allowlist."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for cidr in var.allowed_ip_cidrs : can(cidrnetmask(cidr)) && strcontains(cidr, ".")])
    error_message = "Every allowed_ip_cidrs entry must be a valid IPv4 CIDR."
  }
}

variable "publisher_role_assignments" {
  description = "Topic-scoped publisher RBAC assignments keyed by a stable label."
  type = map(object({
    principal_id                     = string
    role                             = optional(string, "EventGrid Data Sender")
    skip_service_principal_aad_check = optional(bool, false)
  }))
  default = {}
  validation {
    condition     = alltrue([for assignment in values(var.publisher_role_assignments) : length(trimspace(assignment.principal_id)) > 0 && length(trimspace(assignment.role)) > 0])
    error_message = "Every publisher role assignment requires a principal_id and non-empty role."
  }
}

variable "event_subscriptions" {
  description = "Optional event subscriptions keyed by stable label. Endpoints are IDs except webhook URLs and storage-account IDs."
  type = map(object({
    endpoint_type          = string
    endpoint               = string
    storage_queue_name     = optional(string, null)
    included_event_types   = optional(set(string), [])
    subject_begins_with    = optional(string, "")
    subject_ends_with      = optional(string, "")
    subject_case_sensitive = optional(bool, false)
    max_delivery_attempts  = optional(number, 30)
    event_time_to_live     = optional(number, 1440)
  }))
  default = {}
  validation {
    condition = alltrue([
      for subscription in values(var.event_subscriptions) :
      contains(["azure_function", "eventhub", "service_bus_queue", "service_bus_topic", "storage_queue", "webhook"], subscription.endpoint_type) &&
      length(trimspace(subscription.endpoint)) > 0 &&
      (subscription.endpoint_type == "storage_queue" ? subscription.storage_queue_name != null : subscription.storage_queue_name == null) &&
      subscription.max_delivery_attempts >= 1 && subscription.max_delivery_attempts <= 30 &&
      subscription.event_time_to_live >= 1 && subscription.event_time_to_live <= 1440
    ])
    error_message = "Each subscription needs a supported endpoint type, endpoint, storage queue name only when applicable, 1-30 attempts, and 1-1440 minute TTL."
  }
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
