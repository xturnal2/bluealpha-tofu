variable "aws_region" {
  description = "AWS region for the KMS key."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project identifier used in aliases and tags."
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

variable "alias_name" {
  description = "KMS alias without the alias/ prefix, or null for project-environment."
  type        = string
  default     = null
  validation {
    condition     = var.alias_name == null || can(regex("^[A-Za-z0-9/_-]{1,250}$", var.alias_name))
    error_message = "alias_name must be 1-250 letters, numbers, slashes, underscores, or hyphens without alias/."
  }
  validation {
    condition     = var.alias_name == null || !startswith(var.alias_name, "aws/")
    error_message = "alias_name cannot begin with the reserved aws/ prefix."
  }
}

variable "description" {
  description = "Purpose and data classification description for the key."
  type        = string
  default     = "Application encryption key managed by OpenTofu"
}

variable "enable_key_rotation" {
  description = "Enable automatic rotation of symmetric key material."
  type        = bool
  default     = true
}

variable "rotation_period_in_days" {
  description = "Automatic rotation interval from 90 through 2560 days."
  type        = number
  default     = 365
  validation {
    condition     = var.rotation_period_in_days >= 90 && var.rotation_period_in_days <= 2560 && floor(var.rotation_period_in_days) == var.rotation_period_in_days
    error_message = "rotation_period_in_days must be an integer from 90 through 2560."
  }
}

variable "deletion_window_in_days" {
  description = "Waiting period before a scheduled key deletion becomes permanent."
  type        = number
  default     = 30
  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30 && floor(var.deletion_window_in_days) == var.deletion_window_in_days
    error_message = "deletion_window_in_days must be an integer from 7 through 30."
  }
}

variable "multi_region" {
  description = "Create a multi-Region primary key. Replica keys must be managed by connected regional stacks."
  type        = bool
  default     = false
}

variable "allowed_key_administrator_arns" {
  description = "IAM principal ARNs granted key administration except deletion and policy replacement."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for arn in var.allowed_key_administrator_arns : can(regex("^arn:", arn))])
    error_message = "Every allowed_key_administrator_arns entry must be an ARN."
  }
}

variable "allowed_cryptographic_user_arns" {
  description = "IAM principal ARNs granted encrypt/decrypt/data-key operations."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for arn in var.allowed_cryptographic_user_arns : can(regex("^arn:", arn))])
    error_message = "Every allowed_cryptographic_user_arns entry must be an ARN."
  }
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
