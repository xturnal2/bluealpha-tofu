variable "subscription_id" {
  description = "Azure subscription ID used by the provider."
  type        = string
  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a UUID."
  }
}
variable "location" {
  description = "Azure region for the optional alert resource group."
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
variable "alert_name" {
  description = "Metric alert name, or null for a generated name."
  type        = string
  default     = null
}
variable "description" {
  description = "Operational meaning and response guidance."
  type        = string
  default     = "Static metric threshold managed by OpenTofu"
}
variable "scopes" {
  description = "Azure resource IDs evaluated by the alert."
  type        = set(string)
  validation {
    condition     = length(var.scopes) > 0 && alltrue([for scope in var.scopes : startswith(scope, "/subscriptions/")])
    error_message = "scopes must contain at least one Azure resource ID."
  }
}
variable "severity" {
  description = "Azure Monitor severity from 0 (critical) through 4 (verbose)."
  type        = number
  default     = 2
  validation {
    condition     = var.severity >= 0 && var.severity <= 4 && floor(var.severity) == var.severity
    error_message = "severity must be an integer from 0 through 4."
  }
}
variable "enabled" {
  description = "Enable metric evaluation."
  type        = bool
  default     = true
}
variable "auto_mitigate" {
  description = "Automatically resolve the alert when criteria clear."
  type        = bool
  default     = true
}
variable "frequency" {
  description = "ISO 8601 evaluation frequency."
  type        = string
  default     = "PT5M"
  validation {
    condition     = contains(["PT1M", "PT5M", "PT15M", "PT30M", "PT1H"], var.frequency)
    error_message = "frequency must be PT1M, PT5M, PT15M, PT30M, or PT1H."
  }
}
variable "window_size" {
  description = "ISO 8601 aggregation window."
  type        = string
  default     = "PT15M"
  validation {
    condition     = contains(["PT1M", "PT5M", "PT15M", "PT30M", "PT1H", "PT6H", "PT12H", "P1D"], var.window_size)
    error_message = "window_size must be a supported Azure Monitor duration."
  }
}
variable "target_resource_type" {
  description = "Resource type required for multiple or broad scopes."
  type        = string
  default     = null
}
variable "target_resource_location" {
  description = "Resource location required for multiple or broad scopes."
  type        = string
  default     = null
}
variable "criteria" {
  description = "Static metric criteria keyed by stable label. All criteria must breach for the alert to fire."
  type = map(object({
    metric_namespace       = string
    metric_name            = string
    aggregation            = optional(string, "Average")
    operator               = optional(string, "GreaterThan")
    threshold              = number
    skip_metric_validation = optional(bool, false)
    dimensions = optional(map(object({
      operator = optional(string, "Include")
      values   = set(string)
    })), {})
  }))
  validation {
    condition = length(var.criteria) > 0 && alltrue([for criterion in values(var.criteria) :
      contains(["Average", "Count", "Maximum", "Minimum", "Total"], criterion.aggregation) &&
      contains(["Equals", "GreaterThan", "GreaterThanOrEqual", "LessThan", "LessThanOrEqual", "NotEquals"], criterion.operator) &&
      alltrue([for dimension in values(criterion.dimensions) : contains(["Exclude", "Include"], dimension.operator) && length(dimension.values) > 0])
    ])
    error_message = "Provide at least one criterion with supported aggregation, operator, and non-empty dimensions."
  }
}
variable "action_groups" {
  description = "Action group resource IDs keyed by ID, with optional webhook properties."
  type = map(object({
    webhook_properties = optional(map(string), {})
  }))
  default = {}
  validation {
    condition     = alltrue([for id in keys(var.action_groups) : startswith(id, "/subscriptions/")])
    error_message = "Every action_groups key must be an Azure action group resource ID."
  }
}
variable "tags" {
  description = "Additional tags merged with standard tags."
  type        = map(string)
  default     = {}
}
