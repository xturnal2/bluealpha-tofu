variable "aws_region" {
  description = "AWS region for the repository."
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

variable "repository_name" {
  description = "ECR repository name or null for project_name-environment. Paths separated by slashes are supported."
  type        = string
  default     = null
  validation {
    condition     = var.repository_name == null || can(regex("^(?:[a-z0-9]+(?:[._-][a-z0-9]+)*/)*[a-z0-9]+(?:[._-][a-z0-9]+)*$", var.repository_name))
    error_message = "repository_name must be a valid lowercase ECR repository name, optionally using slash-delimited paths."
  }
}

variable "image_tag_mutability" {
  description = "IMMUTABLE prevents an existing tag from being overwritten; MUTABLE permits tag replacement."
  type        = string
  default     = "IMMUTABLE"
  validation {
    condition     = contains(["IMMUTABLE", "MUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be IMMUTABLE or MUTABLE."
  }
}

variable "scan_on_push" {
  description = "Request basic image vulnerability scanning when an image is pushed."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Customer-managed KMS key ARN. Null uses ECR-managed AES-256 encryption."
  type        = string
  default     = null
  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:[^:]+:kms:[^:]+:[0-9]{12}:key/.+$", var.kms_key_arn))
    error_message = "kms_key_arn must be a KMS key ARN or null."
  }
}

variable "force_delete" {
  description = "Allow tofu destroy to delete a non-empty repository. Keep false for deliberate cleanup."
  type        = bool
  default     = false
}

variable "enable_lifecycle_policy" {
  description = "Apply image-retention rules to control storage growth."
  type        = bool
  default     = true
}

variable "untagged_retention_days" {
  description = "Days to retain untagged images before lifecycle expiration."
  type        = number
  default     = 14
  validation {
    condition     = var.untagged_retention_days >= 1 && floor(var.untagged_retention_days) == var.untagged_retention_days
    error_message = "untagged_retention_days must be a positive integer."
  }
}

variable "max_image_count" {
  description = "Maximum total images retained after the untagged-age rule is evaluated."
  type        = number
  default     = 50
  validation {
    condition     = var.max_image_count >= 1 && floor(var.max_image_count) == var.max_image_count
    error_message = "max_image_count must be a positive integer."
  }
}

variable "allowed_pull_principal_arns" {
  description = "IAM principal ARNs granted cross-account pull access through the repository policy."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for arn in var.allowed_pull_principal_arns : can(regex("^arn:", arn))])
    error_message = "Every allowed_pull_principal_arns entry must be an ARN."
  }
}

variable "allowed_push_principal_arns" {
  description = "IAM principal ARNs granted cross-account push and pull access through the repository policy."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for arn in var.allowed_push_principal_arns : can(regex("^arn:", arn))])
    error_message = "Every allowed_push_principal_arns entry must be an ARN."
  }
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
