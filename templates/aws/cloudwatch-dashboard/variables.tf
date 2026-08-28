variable "aws_region" {
  description = "Default AWS region for dashboard metrics."
  type        = string
  default     = "us-east-1"
}
variable "project_name" {
  description = "Short project identifier used in the default dashboard name."
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
variable "dashboard_name" {
  description = "Dashboard name, or null for project-environment-operations."
  type        = string
  default     = null
  validation {
    condition     = var.dashboard_name == null || can(regex("^[A-Za-z0-9_-]{1,255}$", var.dashboard_name))
    error_message = "dashboard_name must be 1-255 letters, numbers, underscores, or hyphens."
  }
}
variable "default_time_range" {
  description = "ISO 8601 relative time range displayed when the dashboard opens."
  type        = string
  default     = "-PT6H"
}
variable "period_override" {
  description = "Whether widget periods or automatic aggregation control display."
  type        = string
  default     = "inherit"
  validation {
    condition     = contains(["auto", "inherit"], var.period_override)
    error_message = "period_override must be auto or inherit."
  }
}
variable "metric_widgets" {
  description = "Metric widgets keyed by stable label. Each widget displays one exact metric time series."
  type = map(object({
    title          = string
    namespace      = string
    metric_name    = string
    dimensions     = optional(map(string), {})
    region         = optional(string, null)
    statistic      = optional(string, "Average")
    period_seconds = optional(number, 300)
    view           = optional(string, "timeSeries")
    stacked        = optional(bool, false)
    x              = number
    y              = number
    width          = optional(number, 12)
    height         = optional(number, 6)
    horizontal_annotations = optional(list(object({
      label = string
      value = number
      color = optional(string, "d62728")
    })), [])
  }))
  default = {}
  validation {
    condition = alltrue([for widget in values(var.metric_widgets) :
      contains(["Average", "Maximum", "Minimum", "SampleCount", "Sum"], widget.statistic) &&
      contains(["bar", "gauge", "pie", "singleValue", "timeSeries"], widget.view) &&
      widget.period_seconds >= 1 && widget.x >= 0 && widget.x <= 23 && widget.y >= 0 &&
      widget.width >= 1 && widget.width <= 24 && widget.height >= 1 && widget.height <= 1000
    ])
    error_message = "Metric widgets require supported statistics/views and valid grid position and dimensions."
  }
}
variable "text_widgets" {
  description = "Markdown text widgets keyed by stable label."
  type = map(object({
    markdown   = string
    background = optional(string, "transparent")
    x          = number
    y          = number
    width      = optional(number, 24)
    height     = optional(number, 3)
  }))
  default = {}
  validation {
    condition = alltrue([for widget in values(var.text_widgets) :
      contains(["solid", "transparent"], widget.background) &&
      widget.x >= 0 && widget.x <= 23 && widget.y >= 0 && widget.width >= 1 && widget.width <= 24 && widget.height >= 1
    ])
    error_message = "Text widgets require a supported background and valid grid position and dimensions."
  }
}
