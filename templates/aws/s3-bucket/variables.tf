variable "aws_region" {
  description = "AWS region for the bucket."
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

variable "bucket_name" {
  description = "Globally unique S3 bucket name, or null for a generated name."
  type        = string
  default     = null
  validation {
    condition     = var.bucket_name == null || can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be 3-63 lowercase letters, numbers, periods, or hyphens and start/end alphanumeric."
  }
  validation {
    condition     = var.bucket_name == null || (!strcontains(var.bucket_name, "..") && !can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", var.bucket_name)))
    error_message = "bucket_name cannot contain consecutive periods or use IPv4 address format."
  }
}

variable "force_destroy" {
  description = "Allow tofu destroy to delete all objects and versions. Keep false for deliberate cleanup."
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Retain prior object versions for recovery."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Customer-managed KMS key ARN. Null uses S3-managed AES-256 encryption."
  type        = string
  default     = null
}

variable "bucket_key_enabled" {
  description = "Use an S3 Bucket Key to reduce KMS requests when a customer-managed key is configured."
  type        = bool
  default     = true
}

variable "enable_lifecycle_policy" {
  description = "Enable multipart cleanup and optional version/current-object expiration."
  type        = bool
  default     = true
}

variable "abort_incomplete_multipart_upload_days" {
  description = "Days before incomplete multipart uploads are aborted."
  type        = number
  default     = 7
  validation {
    condition     = var.abort_incomplete_multipart_upload_days >= 1 && floor(var.abort_incomplete_multipart_upload_days) == var.abort_incomplete_multipart_upload_days
    error_message = "abort_incomplete_multipart_upload_days must be a positive integer."
  }
}

variable "noncurrent_version_expiration_days" {
  description = "Days before noncurrent object versions expire, or null to retain them indefinitely."
  type        = number
  default     = 90
  validation {
    condition     = var.noncurrent_version_expiration_days == null || (var.noncurrent_version_expiration_days >= 1 && floor(var.noncurrent_version_expiration_days) == var.noncurrent_version_expiration_days)
    error_message = "noncurrent_version_expiration_days must be null or a positive integer."
  }
}

variable "object_expiration_days" {
  description = "Days before current objects expire, or null to retain them indefinitely."
  type        = number
  default     = null
  validation {
    condition     = var.object_expiration_days == null || (var.object_expiration_days >= 1 && floor(var.object_expiration_days) == var.object_expiration_days)
    error_message = "object_expiration_days must be null or a positive integer."
  }
}

variable "access_log_target_bucket" {
  description = "Existing S3 bucket name that receives server access logs, or null to disable logging."
  type        = string
  default     = null
}

variable "access_log_target_prefix" {
  description = "Object-key prefix for server access logs."
  type        = string
  default     = "s3-access/"
}

variable "allowed_reader_principal_arns" {
  description = "IAM principal ARNs granted list and object-read access by the bucket policy."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for arn in var.allowed_reader_principal_arns : can(regex("^arn:", arn))])
    error_message = "Every allowed_reader_principal_arns entry must be an ARN."
  }
}

variable "allowed_writer_principal_arns" {
  description = "IAM principal ARNs granted list, read, write, and multipart-object access by the bucket policy."
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
