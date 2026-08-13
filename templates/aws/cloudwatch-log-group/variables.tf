variable "aws_region" {
  description = "AWS region for the log group."
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
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,14}[a-z0-9]$", var.environment))
    error_message = "environment must be 3-16 lowercase letters, numbers, or hyphens."
  }
}

variable "log_group_name" {
  description = "Explicit log group name, or null to use /project/environment/application."
  type        = string
  default     = null

  validation {
    condition     = var.log_group_name == null || can(regex("^[.\\-_/#A-Za-z0-9]{1,512}$", var.log_group_name))
    error_message = "log_group_name must be 1-512 supported CloudWatch Logs name characters."
  }
}

variable "retention_in_days" {
  description = "Number of days to retain log events."
  type        = number
  default     = 30

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545,
      731, 1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.retention_in_days)
    error_message = "retention_in_days must be a retention period supported by CloudWatch Logs."
  }
}

variable "kms_key_arn" {
  description = "Customer-managed symmetric KMS key ARN for log encryption, or null for AWS-managed encryption."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:[^:]+:kms:[^:]+:[0-9]{12}:key/.+$", var.kms_key_arn))
    error_message = "kms_key_arn must be a KMS key ARN."
  }
}

variable "log_group_class" {
  description = "STANDARD for all features or INFREQUENT_ACCESS for lower-cost archival workloads."
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "INFREQUENT_ACCESS"], var.log_group_class)
    error_message = "log_group_class must be STANDARD or INFREQUENT_ACCESS."
  }
}

variable "deletion_protection_enabled" {
  description = "Prevent deletion of the log group until protection is explicitly disabled."
  type        = bool
  default     = true
}

variable "skip_destroy" {
  description = "Remove the log group from state without deleting it during destroy. Use only with an explicit ownership handoff plan."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
