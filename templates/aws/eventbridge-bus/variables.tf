variable "aws_region" {
  description = "AWS region for the event bus."
  type        = string
  default     = "us-east-1"
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

variable "event_bus_name" {
  description = "Custom event bus name or null for project-environment-events."
  type        = string
  default     = null
  validation {
    condition     = var.event_bus_name == null || can(regex("^[A-Za-z0-9._-]{1,256}$", var.event_bus_name))
    error_message = "event_bus_name must be 1-256 letters, numbers, periods, underscores, or hyphens."
  }
}

variable "description" {
  description = "Purpose of the event bus."
  type        = string
  default     = "Application event bus managed by OpenTofu"
}

variable "kms_key_identifier" {
  description = "Customer-managed KMS key ARN, ID, or alias for bus encryption. Null uses an AWS-owned key."
  type        = string
  default     = null
}

variable "dead_letter_queue_arn" {
  description = "SQS queue ARN for bus-level failures related to customer-managed encryption, or null."
  type        = string
  default     = null
  validation {
    condition     = var.dead_letter_queue_arn == null || can(regex("^arn:[^:]+:sqs:", var.dead_letter_queue_arn))
    error_message = "dead_letter_queue_arn must be an SQS queue ARN or null."
  }
}

variable "allowed_put_events_principal_arns" {
  description = "IAM principal ARNs granted events:PutEvents through the bus resource policy."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for arn in var.allowed_put_events_principal_arns : can(regex("^arn:", arn))])
    error_message = "Every allowed_put_events_principal_arns entry must be an ARN."
  }
}

variable "enable_archive" {
  description = "Archive matching events for replay."
  type        = bool
  default     = false
}

variable "archive_retention_days" {
  description = "Days to retain archived events. Null retains them indefinitely."
  type        = number
  default     = 30
  validation {
    condition     = var.archive_retention_days == null || (var.archive_retention_days >= 1 && floor(var.archive_retention_days) == var.archive_retention_days)
    error_message = "archive_retention_days must be null or a positive integer."
  }
}

variable "archive_event_pattern" {
  description = "EventBridge pattern object selecting archived events. Empty archives every event."
  type        = any
  default     = {}
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
