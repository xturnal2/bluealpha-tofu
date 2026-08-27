variable "aws_region" {
  description = "AWS provider region. AWS Budgets is an account-level service."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project identifier used in the default name and tags."
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
  description = "Budget name, or null for project-environment-cost."
  type        = string
  default     = null

  validation {
    condition     = var.budget_name == null || (length(trimspace(var.budget_name)) >= 1 && length(var.budget_name) <= 100 && !strcontains(var.budget_name, ":") && !strcontains(var.budget_name, "\\"))
    error_message = "budget_name must be 1-100 characters and cannot contain a colon or backslash."
  }
}

variable "account_id" {
  description = "Twelve-digit member account ID to budget, or null for the provider account. Payer-account permissions are required for another account."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9]{12}$", var.account_id))
    error_message = "account_id must be a 12-digit AWS account ID."
  }
}

variable "limit_amount" {
  description = "Cost limit for each budget period in the selected currency."
  type        = number
  default     = 100

  validation {
    condition     = var.limit_amount > 0
    error_message = "limit_amount must be greater than zero."
  }
}

variable "currency" {
  description = "Budget currency unit. AWS cost budgets normally use USD."
  type        = string
  default     = "USD"

  validation {
    condition     = can(regex("^[A-Z]{3}$", var.currency))
    error_message = "currency must be a three-letter uppercase currency code."
  }
}

variable "time_unit" {
  description = "Budget recurrence period."
  type        = string
  default     = "MONTHLY"

  validation {
    condition     = contains(["MONTHLY", "QUARTERLY", "ANNUALLY"], var.time_unit)
    error_message = "time_unit must be MONTHLY, QUARTERLY, or ANNUALLY."
  }
}

variable "cost_filters" {
  description = "AWS Budgets cost filters keyed by supported dimension name, such as TagKeyValue, Service, Region, or LinkedAccount."
  type        = map(set(string))
  default     = {}

  validation {
    condition     = alltrue([for name, values in var.cost_filters : length(trimspace(name)) > 0 && length(values) > 0 && alltrue([for value in values : length(trimspace(value)) > 0])])
    error_message = "Every cost filter requires a non-empty name and at least one non-empty value."
  }
}

variable "cost_types" {
  description = "Controls which charge categories contribute to the budget."
  type = object({
    include_credit             = optional(bool, true)
    include_discount           = optional(bool, true)
    include_other_subscription = optional(bool, true)
    include_recurring          = optional(bool, true)
    include_refund             = optional(bool, true)
    include_subscription       = optional(bool, true)
    include_support            = optional(bool, true)
    include_tax                = optional(bool, true)
    include_upfront            = optional(bool, true)
    use_amortized              = optional(bool, false)
    use_blended                = optional(bool, false)
  })
  default = {}
}

variable "notifications" {
  description = "Actual or forecasted threshold notifications keyed by stable label. Budgets alert but do not stop spending."
  type = map(object({
    comparison_operator        = optional(string, "GREATER_THAN")
    notification_type          = optional(string, "ACTUAL")
    threshold                  = number
    threshold_type             = optional(string, "PERCENTAGE")
    subscriber_email_addresses = optional(set(string), [])
    subscriber_sns_topic_arns  = optional(set(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for notification in values(var.notifications) :
      contains(["GREATER_THAN", "LESS_THAN", "EQUAL_TO"], notification.comparison_operator) &&
      contains(["ACTUAL", "FORECASTED"], notification.notification_type) &&
      contains(["PERCENTAGE", "ABSOLUTE_VALUE"], notification.threshold_type) &&
      notification.threshold >= 0 &&
      alltrue([for email in notification.subscriber_email_addresses : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", email))]) &&
      alltrue([for arn in notification.subscriber_sns_topic_arns : can(regex("^arn:[^:]+:sns:[^:]+:[0-9]{12}:.+$", arn))])
    ])
    error_message = "Notifications require supported operators/types, a non-negative threshold, and valid email or SNS subscribers."
  }
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
