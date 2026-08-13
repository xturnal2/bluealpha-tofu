variable "aws_region" {
  description = "AWS region for the primary secret."
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

variable "secret_name" {
  description = "Secret name or path, or null for project/environment/application."
  type        = string
  default     = null
  validation {
    condition     = var.secret_name == null || can(regex("^[A-Za-z0-9/_+=.@-]{1,512}$", var.secret_name))
    error_message = "secret_name must be 1-512 characters from the Secrets Manager supported character set."
  }
}

variable "description" {
  description = "Purpose and ownership description for the secret boundary."
  type        = string
  default     = "Application secret managed outside OpenTofu"
  validation {
    condition     = length(var.description) >= 1 && length(var.description) <= 2048
    error_message = "description must be 1-2048 characters."
  }
}

variable "kms_key_id" {
  description = "Customer-managed KMS key ARN or alias for the primary secret. Null uses aws/secretsmanager."
  type        = string
  default     = null
}

variable "recovery_window_in_days" {
  description = "Days a deleted secret remains recoverable before permanent deletion."
  type        = number
  default     = 30
  validation {
    condition     = var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30 && floor(var.recovery_window_in_days) == var.recovery_window_in_days
    error_message = "recovery_window_in_days must be an integer from 7 through 30."
  }
}

variable "replica_regions" {
  description = "Replica regions keyed by region name, with an optional regional customer-managed KMS key."
  type = map(object({
    kms_key_id = optional(string, null)
  }))
  default = {}
  validation {
    condition     = !contains(keys(var.replica_regions), var.aws_region)
    error_message = "replica_regions must not include the primary aws_region."
  }
}

variable "force_overwrite_replica_secret" {
  description = "Allow replication to overwrite a same-named secret in a replica region."
  type        = bool
  default     = false
}

variable "allowed_reader_principal_arns" {
  description = "IAM principal ARNs granted DescribeSecret and GetSecretValue by the resource policy."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for arn in var.allowed_reader_principal_arns : can(regex("^arn:", arn))])
    error_message = "Every allowed_reader_principal_arns entry must be an ARN."
  }
}

variable "allowed_writer_principal_arns" {
  description = "IAM principal ARNs granted read plus secret-value version management by the resource policy."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for arn in var.allowed_writer_principal_arns : can(regex("^arn:", arn))])
    error_message = "Every allowed_writer_principal_arns entry must be an ARN."
  }
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
