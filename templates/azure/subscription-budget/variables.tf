variable "subscription_id" {
  description = "Azure subscription ID measured by the budget and used by the provider."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a UUID."
  }
}

variable "project_name" {
  description = "Short project identifier used in the default budget name."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,18}[a-z0-9]$", var.project_name))
    error_message = "project_name must be 3-20 lowercase letters, numbers, or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment represented by the budget."
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,14}[a-z0-9]$", var.environment))
    error_message = "environment must be 3-16 lowercase letters, numbers, or hyphens."
  }
}

variable "budget_name" {
  description = "Subscription-unique budget name, or null for project-environment-cost."
  type        = string
  default     = null

  validation {
    condition     = var.budget_name == null || (length(trimspace(var.budget_name)) >= 1 && length(var.budget_name) <= 260)
    error_message = "budget_name must be 1-260 non-whitespace characters when set."
  }
}

variable "amount" {
  description = "Budget amount in the subscription billing currency for each time grain."
  type        = number
  default     = 100

  validation {
    condition     = var.amount > 0
    error_message = "amount must be greater than zero."
  }
}

variable "time_grain" {
  description = "Budget recurrence period."
  type        = string
  default     = "Monthly"

  validation {
    condition     = contains(["Monthly", "Quarterly", "Annually"], var.time_grain)
    error_message = "time_grain must be Monthly, Quarterly, or Annually."
  }
}

variable "start_date" {
  description = "Budget start in RFC3339 UTC format, aligned to the first day of a billing period. Azure restricts how far in the past it may be."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{4}-[0-9]{2}-01T00:00:00Z$", var.start_date)) && can(timecmp(var.start_date, var.start_date))
    error_message = "start_date must be a valid first-of-month RFC3339 UTC timestamp such as 2026-09-01T00:00:00Z."
  }
}

variable "end_date" {
  description = "Optional RFC3339 UTC expiration date; null lets Azure use its service default."
  type        = string
  default     = null

  validation {
    condition     = var.end_date == null || (can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}T00:00:00Z$", var.end_date)) && can(timecmp(var.end_date, var.end_date)))
    error_message = "end_date must be null or a valid RFC3339 UTC midnight timestamp."
  }
}

variable "dimension_filters" {
  description = "Azure Cost Management dimensions keyed by dimension name, such as ResourceGroupName, ServiceName, or ResourceLocation."
  type = map(object({
    operator = optional(string, "In")
    values   = set(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, filter in var.dimension_filters :
      length(trimspace(name)) > 0 &&
      contains(["In"], filter.operator) &&
      length(filter.values) > 0 &&
      alltrue([for value in filter.values : length(trimspace(value)) > 0])
    ])
    error_message = "Every dimension filter requires a name, In operator, and non-empty values."
  }
}

variable "tag_filters" {
  description = "Cost allocation tags keyed by tag name. Tags must be present on usage records to match."
  type = map(object({
    operator = optional(string, "In")
    values   = set(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, filter in var.tag_filters :
      length(trimspace(name)) > 0 &&
      contains(["In"], filter.operator) &&
      length(filter.values) > 0 &&
      alltrue([for value in filter.values : length(trimspace(value)) > 0])
    ])
    error_message = "Every tag filter requires a name, In operator, and non-empty values."
  }
}

variable "notifications" {
  description = "Actual or forecasted budget notifications keyed by stable label. Budgets alert but do not stop spending."
  type = map(object({
    enabled        = optional(bool, true)
    operator       = optional(string, "GreaterThanOrEqualTo")
    threshold      = number
    threshold_type = optional(string, "Actual")
    contact_emails = optional(set(string), [])
    contact_groups = optional(set(string), [])
    contact_roles  = optional(set(string), [])
  }))

  validation {
    condition = length(var.notifications) > 0 && alltrue([
      for notification in values(var.notifications) :
      contains(["EqualTo", "GreaterThan", "GreaterThanOrEqualTo"], notification.operator) &&
      contains(["Actual", "Forecasted"], notification.threshold_type) &&
      notification.threshold >= 0 && notification.threshold <= 1000 &&
      alltrue([for email in notification.contact_emails : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", email))]) &&
      alltrue([for id in notification.contact_groups : startswith(id, "/subscriptions/")]) &&
      alltrue([for role in notification.contact_roles : length(trimspace(role)) > 0])
    ])
    error_message = "Provide at least one valid Actual/Forecasted notification with supported operator, threshold, and contacts."
  }
}
