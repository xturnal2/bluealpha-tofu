variable "aws_region" {
  description = "AWS region for the topic and subscriptions."
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

variable "topic_name" {
  description = "SNS topic name without a FIFO suffix, or null for project_name-environment-events."
  type        = string
  default     = null
  validation {
    condition     = var.topic_name == null || can(regex("^[A-Za-z0-9_-]{1,251}$", var.topic_name))
    error_message = "topic_name must be 1-251 letters, numbers, underscores, or hyphens and must omit .fifo."
  }
}

variable "display_name" {
  description = "Optional human-readable topic display name used by supported endpoints."
  type        = string
  default     = null
  validation {
    condition     = var.display_name == null || length(var.display_name) <= 100
    error_message = "display_name must contain at most 100 characters."
  }
}

variable "fifo_topic" {
  description = "Create an ordered, exactly-once-processing-capable FIFO topic."
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Generate FIFO deduplication IDs from message bodies when publishers omit them."
  type        = bool
  default     = false
}

variable "kms_master_key_id" {
  description = "KMS key ID/ARN/alias for server-side encryption. Defaults to the AWS-managed SNS key."
  type        = string
  default     = "alias/aws/sns"
}

variable "signature_version" {
  description = "Signature version for SNS HTTP delivery. Version 2 uses SHA-256."
  type        = number
  default     = 2
  validation {
    condition     = contains([1, 2], var.signature_version)
    error_message = "signature_version must be 1 or 2."
  }
}

variable "tracing_config" {
  description = "X-Ray tracing mode: PassThrough or Active."
  type        = string
  default     = "PassThrough"
  validation {
    condition     = contains(["PassThrough", "Active"], var.tracing_config)
    error_message = "tracing_config must be PassThrough or Active."
  }
}

variable "archive_policy_days" {
  description = "FIFO-only message archive retention in days, or null to disable archiving."
  type        = number
  default     = null
  validation {
    condition     = var.archive_policy_days == null || (var.archive_policy_days >= 1 && var.archive_policy_days <= 365 && floor(var.archive_policy_days) == var.archive_policy_days)
    error_message = "archive_policy_days must be null or an integer from 1 through 365."
  }
}

variable "subscriptions" {
  description = "Topic subscriptions keyed by a stable label. Endpoint owners must configure any required queue policy or Lambda permission."
  type = map(object({
    protocol                        = string
    endpoint                        = string
    raw_message_delivery            = optional(bool, false)
    filter_policy                   = optional(map(any), null)
    filter_policy_scope             = optional(string, "MessageAttributes")
    dead_letter_queue_arn           = optional(string, null)
    subscription_role_arn           = optional(string, null)
    endpoint_auto_confirms          = optional(bool, false)
    confirmation_timeout_in_minutes = optional(number, 1)
  }))
  default = {}
  validation {
    condition = alltrue([
      for subscription in values(var.subscriptions) :
      contains(["application", "email", "email-json", "firehose", "http", "https", "lambda", "sms", "sqs"], subscription.protocol) &&
      length(trimspace(subscription.endpoint)) > 0 &&
      contains(["MessageAttributes", "MessageBody"], subscription.filter_policy_scope) &&
      subscription.confirmation_timeout_in_minutes >= 1 && subscription.confirmation_timeout_in_minutes <= 10080
    ])
    error_message = "Every subscription must use a supported protocol, non-empty endpoint, valid filter scope, and 1-10080 minute confirmation timeout."
  }
}

variable "allowed_publisher_principal_arns" {
  description = "IAM principal ARNs granted sns:Publish through a topic resource policy. Same-account publishers can instead use identity policies."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for arn in var.allowed_publisher_principal_arns : can(regex("^arn:", arn))])
    error_message = "Every allowed_publisher_principal_arns entry must be an ARN."
  }
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
