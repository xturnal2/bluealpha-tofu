variable "aws_region" {
  description = "AWS region for all resources."
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

variable "function_description" {
  description = "Description assigned to the Lambda function."
  type        = string
  default     = "HTTP API function managed by OpenTofu"
}

variable "source_file" {
  description = "Path to the Lambda source file, relative to this template directory."
  type        = string
  default     = "src/index.py"
}

variable "handler" {
  description = "Lambda entry point matching the packaged source file."
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "Lambda runtime compatible with the source file."
  type        = string
  default     = "python3.13"
}

variable "architecture" {
  description = "Lambda instruction-set architecture."
  type        = string
  default     = "arm64"
  validation {
    condition     = contains(["arm64", "x86_64"], var.architecture)
    error_message = "architecture must be arm64 or x86_64."
  }
}

variable "memory_size" {
  description = "Memory allocated to the function in MiB. CPU scales with memory."
  type        = number
  default     = 128
  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240 && floor(var.memory_size) == var.memory_size
    error_message = "memory_size must be an integer from 128 through 10240 MiB."
  }
}

variable "timeout_seconds" {
  description = "Maximum function execution time in seconds."
  type        = number
  default     = 10
  validation {
    condition     = var.timeout_seconds >= 1 && var.timeout_seconds <= 900 && floor(var.timeout_seconds) == var.timeout_seconds
    error_message = "timeout_seconds must be an integer from 1 through 900."
  }
}

variable "ephemeral_storage_mb" {
  description = "Writable /tmp storage in MiB."
  type        = number
  default     = 512
  validation {
    condition     = var.ephemeral_storage_mb >= 512 && var.ephemeral_storage_mb <= 10240 && floor(var.ephemeral_storage_mb) == var.ephemeral_storage_mb
    error_message = "ephemeral_storage_mb must be an integer from 512 through 10240 MiB."
  }
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrency. -1 leaves it unreserved; 0 disables invocation."
  type        = number
  default     = -1
  validation {
    condition     = var.reserved_concurrent_executions == -1 || (var.reserved_concurrent_executions >= 0 && floor(var.reserved_concurrent_executions) == var.reserved_concurrent_executions)
    error_message = "reserved_concurrent_executions must be -1 or a non-negative integer."
  }
}

variable "environment_variables" {
  description = "Function environment variables. Values are stored in OpenTofu state."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "log_retention_days" {
  description = "CloudWatch retention for function and API logs. Null never expires logs."
  type        = number
  default     = 30
  validation {
    condition     = var.log_retention_days == null || contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be null or a CloudWatch Logs supported retention period."
  }
}

variable "tracing_mode" {
  description = "X-Ray tracing mode. Active adds the required managed policy."
  type        = string
  default     = "PassThrough"
  validation {
    condition     = contains(["Active", "PassThrough"], var.tracing_mode)
    error_message = "tracing_mode must be Active or PassThrough."
  }
}

variable "vpc_subnet_ids" {
  description = "Private subnet IDs for optional Lambda VPC attachment."
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "Security group IDs for optional Lambda VPC attachment."
  type        = list(string)
  default     = []
}

variable "cors_allowed_origins" {
  description = "Origins allowed by HTTP API CORS. Empty disables API-managed CORS."
  type        = list(string)
  default     = []
}

variable "cors_allowed_headers" {
  description = "Request headers allowed by CORS."
  type        = list(string)
  default     = ["content-type"]
}

variable "cors_allowed_methods" {
  description = "HTTP methods allowed by CORS."
  type        = list(string)
  default     = ["GET", "POST", "OPTIONS"]
}

variable "cors_allow_credentials" {
  description = "Permit browsers to include credentials in cross-origin requests."
  type        = bool
  default     = false
}

variable "cors_max_age_seconds" {
  description = "Browser preflight cache duration."
  type        = number
  default     = 300
  validation {
    condition     = var.cors_max_age_seconds >= 0 && var.cors_max_age_seconds <= 86400
    error_message = "cors_max_age_seconds must be from 0 through 86400."
  }
}

variable "throttle_burst_limit" {
  description = "Maximum API request burst."
  type        = number
  default     = 100
  validation {
    condition     = var.throttle_burst_limit >= 0 && floor(var.throttle_burst_limit) == var.throttle_burst_limit
    error_message = "throttle_burst_limit must be a non-negative integer."
  }
}

variable "throttle_rate_limit" {
  description = "Steady-state API requests per second."
  type        = number
  default     = 50
  validation {
    condition     = var.throttle_rate_limit >= 0
    error_message = "throttle_rate_limit must be non-negative."
  }
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
