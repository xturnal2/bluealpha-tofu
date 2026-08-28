variable "subscription_id" {
  description = "Azure subscription ID used by the provider."
  type        = string
  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a UUID."
  }
}
variable "location" {
  description = "Azure region for the optional resource group."
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
  description = "Create the monitoring resource group."
  type        = bool
  default     = true
}
variable "resource_group_name" {
  description = "Existing resource group when creation is disabled."
  type        = string
  default     = null
}
variable "action_group_name" {
  description = "Action group name, or null for a generated name."
  type        = string
  default     = null
}
variable "short_name" {
  description = "Twelve-character identifier used in some notifications."
  type        = string
  default     = "platform"
  validation {
    condition     = can(regex("^[A-Za-z0-9_-]{1,12}$", var.short_name))
    error_message = "short_name must be 1-12 letters, numbers, underscores, or hyphens."
  }
}
variable "enabled" {
  description = "Enable delivery to receivers."
  type        = bool
  default     = true
}
variable "email_receivers" {
  description = "Email receivers keyed by unique receiver name."
  type = map(object({
    email_address           = string
    use_common_alert_schema = optional(bool, true)
  }))
  default = {}
  validation {
    condition     = alltrue([for receiver in values(var.email_receivers) : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", receiver.email_address))])
    error_message = "Every email receiver must contain a valid email address."
  }
}
variable "webhook_receivers" {
  description = "HTTPS webhook receivers keyed by name, with optional Entra authentication. Do not embed secrets in URLs."
  type = map(object({
    service_uri             = string
    use_common_alert_schema = optional(bool, true)
    aad_auth = optional(object({
      object_id      = string
      identifier_uri = optional(string, null)
      tenant_id      = optional(string, null)
    }), null)
  }))
  default = {}
  validation {
    condition = alltrue([for receiver in values(var.webhook_receivers) :
      startswith(receiver.service_uri, "https://") &&
      (receiver.aad_auth == null || can(regex("^[0-9a-fA-F-]{36}$", receiver.aad_auth.object_id)))
    ])
    error_message = "Webhooks require HTTPS URLs and any Entra object_id must be a UUID."
  }
}
variable "tags" {
  description = "Additional tags merged with standard tags."
  type        = map(string)
  default     = {}
}
