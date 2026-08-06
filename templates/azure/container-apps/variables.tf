variable "subscription_id" {
  description = "Azure subscription ID. Null uses ARM_SUBSCRIPTION_ID from the environment."
  type        = string
  default     = null
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

variable "location" {
  description = "Azure region."
  type        = string
  default     = "eastus"
}

variable "create_resource_group" {
  description = "Create a resource group. Set false to reuse an existing group."
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Existing resource group name or null for a generated name. Required when create_resource_group is false."
  type        = string
  default     = null
}

variable "container_image" {
  description = "Container image URI, ideally pinned to an immutable digest or version tag."
  type        = string
}

variable "container_port" {
  description = "Application port exposed by ingress."
  type        = number
  default     = 8080
  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535
    error_message = "container_port must be from 1 through 65535."
  }
}

variable "container_cpu" {
  description = "CPU cores allocated to each replica."
  type        = number
  default     = 0.5
  validation {
    condition     = contains([0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2], var.container_cpu)
    error_message = "container_cpu must be a supported Consumption workload value from 0.25 through 2 cores."
  }
}

variable "container_memory" {
  description = "Memory allocated to each replica. Must match the selected CPU."
  type        = string
  default     = "1Gi"
}

variable "min_replicas" {
  description = "Minimum replica count. Zero permits scale to zero."
  type        = number
  default     = 0
  validation {
    condition     = var.min_replicas >= 0 && floor(var.min_replicas) == var.min_replicas
    error_message = "min_replicas must be a non-negative integer."
  }
}

variable "max_replicas" {
  description = "Maximum replica count."
  type        = number
  default     = 3
  validation {
    condition     = var.max_replicas >= 1 && floor(var.max_replicas) == var.max_replicas
    error_message = "max_replicas must be a positive integer."
  }
}

variable "revision_mode" {
  description = "Single routes to the latest revision; Multiple permits traffic splitting."
  type        = string
  default     = "Single"
  validation {
    condition     = contains(["Single", "Multiple"], var.revision_mode)
    error_message = "revision_mode must be Single or Multiple."
  }
}

variable "enable_ingress" {
  description = "Enable HTTP ingress for the container app."
  type        = bool
  default     = true
}

variable "external_ingress_enabled" {
  description = "Expose ingress publicly. False restricts ingress to the Container Apps environment."
  type        = bool
  default     = false
}

variable "ingress_transport" {
  description = "Ingress transport protocol."
  type        = string
  default     = "auto"
  validation {
    condition     = contains(["auto", "http", "http2", "tcp"], var.ingress_transport)
    error_message = "ingress_transport must be auto, http, http2, or tcp."
  }
}

variable "ingress_ip_restrictions" {
  description = "Named ingress IP restrictions keyed by rule name."
  type = map(object({
    action      = string
    cidr        = string
    description = optional(string, null)
  }))
  default = {}
  validation {
    condition = (
      alltrue([for rule in values(var.ingress_ip_restrictions) : contains(["Allow", "Deny"], rule.action) && can(cidrnetmask(rule.cidr))]) &&
      length(distinct([for rule in values(var.ingress_ip_restrictions) : rule.action])) <= 1
    )
    error_message = "Ingress restrictions require valid IPv4 CIDRs and must all use the same Allow or Deny action."
  }
}

variable "http_scale_concurrent_requests" {
  description = "Concurrent HTTP requests per replica targeted by the HTTP scaler."
  type        = number
  default     = 50
  validation {
    condition     = var.http_scale_concurrent_requests >= 1
    error_message = "http_scale_concurrent_requests must be at least 1."
  }
}

variable "environment_variables" {
  description = "Non-sensitive environment variables."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secret name-to-value map stored by Container Apps. Values are sensitive but remain in OpenTofu state."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "secret_environment_variables" {
  description = "Map of container environment variable names to keys in secrets."
  type        = map(string)
  default     = {}
}

variable "infrastructure_subnet_id" {
  description = "Optional delegated subnet ID for VNet integration."
  type        = string
  default     = null
}

variable "internal_load_balancer_enabled" {
  description = "Use an internal load balancer for the environment. Requires infrastructure_subnet_id."
  type        = bool
  default     = false
}

variable "zone_redundancy_enabled" {
  description = "Enable zone redundancy for the environment where supported. Requires infrastructure_subnet_id."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Log Analytics retention in days."
  type        = number
  default     = 30
  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "log_retention_days must be from 30 through 730."
  }
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
