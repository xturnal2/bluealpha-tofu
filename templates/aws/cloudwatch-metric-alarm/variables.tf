variable "aws_region" {
  description = "AWS region containing the metric."
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

variable "alarm_name" {
  description = "Alarm name, or null for a generated name."
  type        = string
  default     = null
}

variable "alarm_description" {
  description = "Operational meaning and response guidance."
  type        = string
  default     = "Metric threshold alarm managed by OpenTofu"
}

variable "namespace" {
  description = "CloudWatch metric namespace, such as AWS/ApplicationELB."
  type        = string
}

variable "metric_name" {
  description = "Metric name within the namespace."
  type        = string
}

variable "dimensions" {
  description = "Exact metric dimensions."
  type        = map(string)
  default     = {}
}

variable "statistic" {
  description = "Aggregation applied to each period."
  type        = string
  default     = "Average"
  validation {
    condition     = contains(["Average", "Maximum", "Minimum", "SampleCount", "Sum"], var.statistic)
    error_message = "statistic must be Average, Maximum, Minimum, SampleCount, or Sum."
  }
}

variable "unit" {
  description = "Optional CloudWatch metric unit; null avoids filtering by unit."
  type        = string
  default     = null
}

variable "period_seconds" {
  description = "Metric aggregation period in seconds."
  type        = number
  default     = 300
  validation {
    condition     = var.period_seconds >= 10 && floor(var.period_seconds) == var.period_seconds
    error_message = "period_seconds must be an integer of at least 10."
  }
}

variable "evaluation_periods" {
  description = "Number of recent periods evaluated."
  type        = number
  default     = 3
  validation {
    condition     = var.evaluation_periods >= 1 && floor(var.evaluation_periods) == var.evaluation_periods
    error_message = "evaluation_periods must be a positive integer."
  }
}

variable "datapoints_to_alarm" {
  description = "Breaching periods required within the evaluation window."
  type        = number
  default     = 2
  validation {
    condition     = var.datapoints_to_alarm >= 1 && floor(var.datapoints_to_alarm) == var.datapoints_to_alarm
    error_message = "datapoints_to_alarm must be a positive integer."
  }
}

variable "comparison_operator" {
  description = "How the statistic is compared with the threshold."
  type        = string
  default     = "GreaterThanThreshold"
  validation {
    condition     = contains(["GreaterThanOrEqualToThreshold", "GreaterThanThreshold", "LessThanOrEqualToThreshold", "LessThanThreshold"], var.comparison_operator)
    error_message = "comparison_operator must be a supported static threshold operator."
  }
}

variable "threshold" {
  description = "Numeric alarm threshold in metric units."
  type        = number
}

variable "treat_missing_data" {
  description = "How missing periods affect state."
  type        = string
  default     = "missing"
  validation {
    condition     = contains(["breaching", "ignore", "missing", "notBreaching"], var.treat_missing_data)
    error_message = "treat_missing_data must be breaching, ignore, missing, or notBreaching."
  }
}

variable "actions_enabled" {
  description = "Allow state transitions to invoke configured actions."
  type        = bool
  default     = true
}

variable "alarm_action_arns" {
  description = "SNS topics or other supported actions invoked on ALARM."
  type        = set(string)
  default     = []
}

variable "ok_action_arns" {
  description = "Supported actions invoked when the alarm returns to OK."
  type        = set(string)
  default     = []
}

variable "insufficient_data_action_arns" {
  description = "Supported actions invoked on INSUFFICIENT_DATA."
  type        = set(string)
  default     = []
}

variable "tags" {
  description = "Additional tags merged with standard tags."
  type        = map(string)
  default     = {}
}
