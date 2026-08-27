variable "aws_region" {
  description = "AWS provider region. IAM roles are global within an AWS account."
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

variable "role_name" {
  description = "IAM role name, or null for project-environment-workload."
  type        = string
  default     = null

  validation {
    condition     = var.role_name == null || can(regex("^[A-Za-z0-9+=,.@_-]{1,64}$", var.role_name))
    error_message = "role_name must be 1-64 IAM-supported characters."
  }
}

variable "description" {
  description = "Human-readable purpose and ownership of the role."
  type        = string
  default     = "Workload role managed by OpenTofu"

  validation {
    condition     = length(var.description) <= 1000
    error_message = "description must not exceed 1000 characters."
  }
}

variable "path" {
  description = "IAM path used to organize the role."
  type        = string
  default     = "/"

  validation {
    condition     = can(regex("^/([A-Za-z0-9+=,.@_-]+/)*$", var.path)) && length(var.path) <= 512
    error_message = "path must be a slash-delimited IAM path no longer than 512 characters."
  }
}

variable "trusted_service_principals" {
  description = "AWS services allowed to assume the role, such as ecs-tasks.amazonaws.com."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for principal in var.trusted_service_principals : can(regex("^[A-Za-z0-9.-]+\\.amazonaws\\.com(\\.cn)?$", principal))])
    error_message = "Every trusted service principal must be an AWS service DNS principal."
  }
}

variable "trusted_aws_principal_arns" {
  description = "IAM users, roles, accounts, or federated principals allowed to assume the role."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for arn in var.trusted_aws_principal_arns : can(regex("^arn:[^:]+:iam::[0-9]{12}:(root|role/.+|user/.+)$", arn))])
    error_message = "Every trusted AWS principal must be an IAM root, role, or user ARN."
  }
}

variable "external_id" {
  description = "External ID required from trusted AWS principals for third-party confused-deputy protection."
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.external_id == null || (length(var.external_id) >= 2 && length(var.external_id) <= 1224)
    error_message = "external_id must be 2-1224 characters when set."
  }
}

variable "require_mfa" {
  description = "Require MFA when an AWS principal assumes this role. Do not use for service principals."
  type        = bool
  default     = false
}

variable "permissions_boundary_arn" {
  description = "IAM managed policy ARN used as the role's maximum permissions boundary."
  type        = string
  default     = null

  validation {
    condition     = var.permissions_boundary_arn == null || can(regex("^arn:[^:]+:iam::[0-9]{12}:policy/.+$", var.permissions_boundary_arn))
    error_message = "permissions_boundary_arn must be an IAM managed policy ARN."
  }
}

variable "max_session_duration_seconds" {
  description = "Maximum role session duration in seconds."
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration_seconds >= 3600 && var.max_session_duration_seconds <= 43200 && floor(var.max_session_duration_seconds) == var.max_session_duration_seconds
    error_message = "max_session_duration_seconds must be an integer from 3600 through 43200."
  }
}

variable "managed_policy_arns" {
  description = "Managed policy ARNs attached to the role. Prefer customer-managed least-privilege policies over broad AWS-managed policies."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for arn in var.managed_policy_arns : can(regex("^arn:[^:]+:iam::(aws|[0-9]{12}):policy/.+$", arn))])
    error_message = "Every managed_policy_arns entry must be an IAM managed policy ARN."
  }
}

variable "inline_policies" {
  description = "Inline IAM policy JSON documents keyed by policy name."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for name, policy in var.inline_policies :
      can(regex("^[A-Za-z0-9+=,.@_-]{1,128}$", name)) && can(jsondecode(policy))
    ])
    error_message = "Each inline policy needs an IAM-supported name and valid JSON document."
  }
}

variable "force_detach_policies" {
  description = "Detach policies outside this stack during role deletion. Enable only after reviewing external ownership."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
