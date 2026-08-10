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

variable "queue_name" {
  description = "Queue name without the .fifo suffix, or null for a generated name."
  type        = string
  default     = null
  validation {
    condition     = var.queue_name == null || can(regex("^[A-Za-z0-9_-]{1,70}$", var.queue_name))
    error_message = "queue_name must contain 1-70 letters, numbers, hyphens, or underscores without a .fifo suffix."
  }
}

variable "fifo_queue" {
  description = "Create FIFO queues for ordered, deduplicated processing."
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Generate FIFO deduplication IDs from message bodies. Only valid for FIFO queues."
  type        = bool
  default     = false
}

variable "high_throughput_fifo" {
  description = "Use message-group deduplication and per-message-group throughput for a FIFO queue."
  type        = bool
  default     = false
}

variable "delay_seconds" {
  description = "Delay applied to newly sent messages."
  type        = number
  default     = 0
  validation {
    condition     = var.delay_seconds >= 0 && var.delay_seconds <= 900 && floor(var.delay_seconds) == var.delay_seconds
    error_message = "delay_seconds must be an integer from 0 through 900."
  }
}

variable "maximum_message_size" {
  description = "Maximum accepted message size in bytes."
  type        = number
  default     = 1048576
  validation {
    condition     = var.maximum_message_size >= 1024 && var.maximum_message_size <= 1048576 && floor(var.maximum_message_size) == var.maximum_message_size
    error_message = "maximum_message_size must be an integer from 1024 through 1048576 bytes."
  }
}

variable "message_retention_seconds" {
  description = "How long unconsumed source-queue messages are retained."
  type        = number
  default     = 345600
  validation {
    condition     = var.message_retention_seconds >= 60 && var.message_retention_seconds <= 1209600 && floor(var.message_retention_seconds) == var.message_retention_seconds
    error_message = "message_retention_seconds must be an integer from 60 through 1209600."
  }
}

variable "visibility_timeout_seconds" {
  description = "Time a received message remains hidden from other consumers."
  type        = number
  default     = 30
  validation {
    condition     = var.visibility_timeout_seconds >= 0 && var.visibility_timeout_seconds <= 43200 && floor(var.visibility_timeout_seconds) == var.visibility_timeout_seconds
    error_message = "visibility_timeout_seconds must be an integer from 0 through 43200."
  }
}

variable "receive_wait_time_seconds" {
  description = "Long-poll wait time for ReceiveMessage calls."
  type        = number
  default     = 20
  validation {
    condition     = var.receive_wait_time_seconds >= 0 && var.receive_wait_time_seconds <= 20 && floor(var.receive_wait_time_seconds) == var.receive_wait_time_seconds
    error_message = "receive_wait_time_seconds must be an integer from 0 through 20."
  }
}

variable "create_dead_letter_queue" {
  description = "Create a matching dead-letter queue and configure source redrive."
  type        = bool
  default     = true
}

variable "max_receive_count" {
  description = "Delivery attempts before a message moves to the dead-letter queue."
  type        = number
  default     = 5
  validation {
    condition     = var.max_receive_count >= 1 && var.max_receive_count <= 1000 && floor(var.max_receive_count) == var.max_receive_count
    error_message = "max_receive_count must be an integer from 1 through 1000."
  }
}

variable "dead_letter_retention_seconds" {
  description = "How long messages remain in the dead-letter queue."
  type        = number
  default     = 1209600
  validation {
    condition     = var.dead_letter_retention_seconds >= 60 && var.dead_letter_retention_seconds <= 1209600 && floor(var.dead_letter_retention_seconds) == var.dead_letter_retention_seconds
    error_message = "dead_letter_retention_seconds must be an integer from 60 through 1209600."
  }
}

variable "kms_master_key_id" {
  description = "Customer-managed KMS key ID/ARN/alias. Null uses SQS-managed server-side encryption."
  type        = string
  default     = null
}

variable "kms_data_key_reuse_period_seconds" {
  description = "How long SQS may reuse a KMS data key when a customer-managed key is selected."
  type        = number
  default     = 300
  validation {
    condition     = var.kms_data_key_reuse_period_seconds >= 60 && var.kms_data_key_reuse_period_seconds <= 86400
    error_message = "kms_data_key_reuse_period_seconds must be from 60 through 86400."
  }
}

variable "allowed_sns_topic_arns" {
  description = "SNS topic ARNs allowed to send messages to the source queue."
  type        = set(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
