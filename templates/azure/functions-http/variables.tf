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

variable "function_app_name" {
  description = "Globally unique Function App name or null to append a stable random suffix."
  type        = string
  default     = null
  validation {
    condition     = var.function_app_name == null || can(regex("^[A-Za-z0-9][A-Za-z0-9-]{0,58}[A-Za-z0-9]$", var.function_app_name))
    error_message = "function_app_name must be 2-60 letters, numbers, or hyphens without leading or trailing hyphens."
  }
}

variable "plan_sku_name" {
  description = "Linux App Service plan SKU. Y1 is Consumption; EP1-EP3 are Elastic Premium."
  type        = string
  default     = "Y1"
  validation {
    condition     = can(regex("^(Y1|EP[1-3]|B[1-3]|S[1-3]|P[1-3]v[2-4])$", var.plan_sku_name))
    error_message = "plan_sku_name must be Y1, EP1-EP3, B1-B3, S1-S3, or P1v2-P3v4."
  }
}

variable "worker_count" {
  description = "Plan worker count where the selected SKU supports explicit workers."
  type        = number
  default     = null
  validation {
    condition     = var.worker_count == null || (var.worker_count >= 1 && floor(var.worker_count) == var.worker_count)
    error_message = "worker_count must be null or a positive integer."
  }
}

variable "runtime_name" {
  description = "Function language runtime."
  type        = string
  default     = "python"
  validation {
    condition     = contains(["python", "node", "dotnet-isolated", "powershell"], var.runtime_name)
    error_message = "runtime_name must be python, node, dotnet-isolated, or powershell."
  }
}

variable "runtime_version" {
  description = "Version accepted by Azure for the selected runtime, such as 3.13, 22, 8.0, or 7.4."
  type        = string
  default     = "3.13"
  validation {
    condition     = length(trimspace(var.runtime_version)) > 0
    error_message = "runtime_version must not be empty."
  }
}

variable "functions_extension_version" {
  description = "Azure Functions host version."
  type        = string
  default     = "~4"
}

variable "always_on" {
  description = "Keep the app loaded. Not supported by the Y1 Consumption plan."
  type        = bool
  default     = false
}

variable "maximum_instance_count" {
  description = "Maximum function scale-out count where supported, or null for the platform default."
  type        = number
  default     = null
  validation {
    condition     = var.maximum_instance_count == null || (var.maximum_instance_count >= 1 && floor(var.maximum_instance_count) == var.maximum_instance_count)
    error_message = "maximum_instance_count must be null or a positive integer."
  }
}

variable "pre_warmed_instance_count" {
  description = "Pre-warmed instance count for Elastic Premium plans, or null."
  type        = number
  default     = null
  validation {
    condition     = var.pre_warmed_instance_count == null || (var.pre_warmed_instance_count >= 0 && floor(var.pre_warmed_instance_count) == var.pre_warmed_instance_count)
    error_message = "pre_warmed_instance_count must be null or a non-negative integer."
  }
}

variable "application_settings" {
  description = "Additional Function App settings. Values are sensitive and remain in OpenTofu state."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "storage_replication_type" {
  description = "Replication type for the runtime storage account."
  type        = string
  default     = "LRS"
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage_replication_type)
    error_message = "storage_replication_type must be LRS, GRS, RAGRS, ZRS, GZRS, or RAGZRS."
  }
}

variable "public_network_access_enabled" {
  description = "Allow the public Function App endpoint. Disabling requires separately managed private connectivity."
  type        = bool
  default     = true
}

variable "ip_restrictions" {
  description = "Named inbound restrictions. Each rule must set exactly one of ip_address, service_tag, or virtual_network_subnet_id."
  type = map(object({
    action                    = optional(string, "Allow")
    priority                  = number
    description               = optional(string, null)
    ip_address                = optional(string, null)
    service_tag               = optional(string, null)
    virtual_network_subnet_id = optional(string, null)
  }))
  default = {}
  validation {
    condition = alltrue([
      for rule in values(var.ip_restrictions) :
      contains(["Allow", "Deny"], rule.action) &&
      length(compact([rule.ip_address, rule.service_tag, rule.virtual_network_subnet_id])) == 1
    ])
    error_message = "Each IP restriction needs Allow/Deny and exactly one IP CIDR, service tag, or subnet ID."
  }
}

variable "ip_restriction_default_action" {
  description = "Action for requests that match no rule. Null uses Deny when rules exist and Allow otherwise."
  type        = string
  default     = null
  validation {
    condition     = var.ip_restriction_default_action == null || contains(["Allow", "Deny"], var.ip_restriction_default_action)
    error_message = "ip_restriction_default_action must be null, Allow, or Deny."
  }
}

variable "cors_allowed_origins" {
  description = "Origins allowed by platform CORS. Empty disables platform-managed CORS."
  type        = list(string)
  default     = []
}

variable "cors_support_credentials" {
  description = "Permit credentials in browser cross-origin requests."
  type        = bool
  default     = false
}

variable "virtual_network_subnet_id" {
  description = "Optional delegated subnet ID for outbound regional VNet integration."
  type        = string
  default     = null
}

variable "vnet_route_all_enabled" {
  description = "Route all outbound app traffic through VNet integration."
  type        = bool
  default     = false
}

variable "health_check_path" {
  description = "Optional health-check path, such as /api/health."
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "Log Analytics and Application Insights retention."
  type        = number
  default     = 30
  validation {
    condition     = contains([30, 60, 90, 120, 180, 270, 365, 550, 730], var.log_retention_days)
    error_message = "log_retention_days must be 30, 60, 90, 120, 180, 270, 365, 550, or 730."
  }
}

variable "application_insights_sampling_percentage" {
  description = "Percentage of telemetry retained by Application Insights sampling."
  type        = number
  default     = 100
  validation {
    condition     = var.application_insights_sampling_percentage > 0 && var.application_insights_sampling_percentage <= 100
    error_message = "application_insights_sampling_percentage must be greater than 0 and at most 100."
  }
}

variable "application_insights_daily_cap_gb" {
  description = "Application Insights daily ingestion cap in GiB."
  type        = number
  default     = 1
  validation {
    condition     = var.application_insights_daily_cap_gb > 0
    error_message = "application_insights_daily_cap_gb must be greater than 0."
  }
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
