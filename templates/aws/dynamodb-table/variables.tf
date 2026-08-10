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

variable "table_name" {
  description = "DynamoDB table name or null for a generated name."
  type        = string
  default     = null
  validation {
    condition     = var.table_name == null || can(regex("^[A-Za-z0-9_.-]{3,255}$", var.table_name))
    error_message = "table_name must be 3-255 letters, numbers, underscores, hyphens, or periods."
  }
}

variable "hash_key" {
  description = "Table partition-key attribute name."
  type        = string
  default     = "id"
}

variable "hash_key_type" {
  description = "Partition-key scalar type: S (string), N (number), or B (binary)."
  type        = string
  default     = "S"
  validation {
    condition     = contains(["S", "N", "B"], var.hash_key_type)
    error_message = "hash_key_type must be S, N, or B."
  }
}

variable "range_key" {
  description = "Optional table sort-key attribute name."
  type        = string
  default     = null
}

variable "range_key_type" {
  description = "Sort-key scalar type when range_key is set."
  type        = string
  default     = "S"
  validation {
    condition     = contains(["S", "N", "B"], var.range_key_type)
    error_message = "range_key_type must be S, N, or B."
  }
}

variable "attribute_types" {
  description = "Scalar types for every secondary-index key not already declared as a table key. Do not include non-key attributes."
  type        = map(string)
  default     = {}
  validation {
    condition     = alltrue([for value in values(var.attribute_types) : contains(["S", "N", "B"], value)])
    error_message = "Every attribute_types value must be S, N, or B."
  }
}

variable "billing_mode" {
  description = "PAY_PER_REQUEST for on-demand billing or PROVISIONED for explicit capacity."
  type        = string
  default     = "PAY_PER_REQUEST"
  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "billing_mode must be PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "read_capacity" {
  description = "Table read capacity units in PROVISIONED mode."
  type        = number
  default     = 5
  validation {
    condition     = var.read_capacity >= 1 && floor(var.read_capacity) == var.read_capacity
    error_message = "read_capacity must be a positive integer."
  }
}

variable "write_capacity" {
  description = "Table write capacity units in PROVISIONED mode."
  type        = number
  default     = 5
  validation {
    condition     = var.write_capacity >= 1 && floor(var.write_capacity) == var.write_capacity
    error_message = "write_capacity must be a positive integer."
  }
}

variable "global_secondary_indexes" {
  description = "Global secondary indexes keyed by index name. Index key types belong in attribute_types."
  type = map(object({
    hash_key           = string
    range_key          = optional(string, null)
    projection_type    = optional(string, "ALL")
    non_key_attributes = optional(list(string), [])
    read_capacity      = optional(number, null)
    write_capacity     = optional(number, null)
  }))
  default = {}
  validation {
    condition = alltrue([
      for index in values(var.global_secondary_indexes) :
      contains(["ALL", "KEYS_ONLY", "INCLUDE"], index.projection_type) &&
      (index.projection_type == "INCLUDE" ? length(index.non_key_attributes) > 0 : length(index.non_key_attributes) == 0) &&
      (index.read_capacity == null || index.read_capacity >= 1) &&
      (index.write_capacity == null || index.write_capacity >= 1)
    ])
    error_message = "GSI projections and optional capacities must be valid; only INCLUDE accepts non_key_attributes."
  }
}

variable "local_secondary_indexes" {
  description = "Local secondary indexes keyed by index name. Each uses the table partition key and a declared alternate sort key."
  type = map(object({
    range_key          = string
    projection_type    = optional(string, "ALL")
    non_key_attributes = optional(list(string), [])
  }))
  default = {}
  validation {
    condition = alltrue([
      for index in values(var.local_secondary_indexes) :
      contains(["ALL", "KEYS_ONLY", "INCLUDE"], index.projection_type) &&
      (index.projection_type == "INCLUDE" ? length(index.non_key_attributes) > 0 : length(index.non_key_attributes) == 0)
    ])
    error_message = "LSI projections must be ALL, KEYS_ONLY, or INCLUDE; only INCLUDE accepts non_key_attributes."
  }
}

variable "table_class" {
  description = "STANDARD or STANDARD_INFREQUENT_ACCESS table storage class."
  type        = string
  default     = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "STANDARD_INFREQUENT_ACCESS"], var.table_class)
    error_message = "table_class must be STANDARD or STANDARD_INFREQUENT_ACCESS."
  }
}

variable "deletion_protection_enabled" {
  description = "Protect the table from deletion through the DynamoDB API. Disable before tofu destroy."
  type        = bool
  default     = true
}

variable "point_in_time_recovery_enabled" {
  description = "Enable continuous point-in-time backups."
  type        = bool
  default     = true
}

variable "recovery_period_in_days" {
  description = "PITR recovery window in days."
  type        = number
  default     = 35
  validation {
    condition     = var.recovery_period_in_days >= 1 && var.recovery_period_in_days <= 35 && floor(var.recovery_period_in_days) == var.recovery_period_in_days
    error_message = "recovery_period_in_days must be an integer from 1 through 35."
  }
}

variable "kms_key_arn" {
  description = "Customer-managed KMS key ARN. Null uses the DynamoDB-owned encryption key."
  type        = string
  default     = null
}

variable "ttl_enabled" {
  description = "Enable asynchronous item expiration using ttl_attribute_name."
  type        = bool
  default     = false
}

variable "ttl_attribute_name" {
  description = "Number attribute containing expiration time as Unix epoch seconds."
  type        = string
  default     = "expires_at"
}

variable "stream_enabled" {
  description = "Enable DynamoDB Streams change data capture."
  type        = bool
  default     = false
}

variable "stream_view_type" {
  description = "Data written to stream records when streams are enabled."
  type        = string
  default     = "NEW_AND_OLD_IMAGES"
  validation {
    condition     = contains(["KEYS_ONLY", "NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES"], var.stream_view_type)
    error_message = "stream_view_type must be KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, or NEW_AND_OLD_IMAGES."
  }
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
