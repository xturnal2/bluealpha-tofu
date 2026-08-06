variable "subscription_id" {
  description = "Azure subscription ID. Null uses ARM_SUBSCRIPTION_ID from the environment."
  type        = string
  default     = null

  validation {
    condition     = var.subscription_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be null or a valid UUID."
  }
}

variable "project_name" {
  description = "Short project identifier used in resource names and tags."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,18}[a-z0-9]$", var.project_name))
    error_message = "project_name must be 3-20 lowercase letters, numbers, or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment, such as dev, test, stage, or prod."
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,14}[a-z0-9]$", var.environment))
    error_message = "environment must be 3-16 lowercase letters, numbers, or hyphens."
  }
}

variable "location" {
  description = "Azure region for the resource group and storage account."
  type        = string
  default     = "eastus"
}

variable "create_resource_group" {
  description = "Create a resource group for this stack. Set false to use an existing group."
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Resource group name. Null generates <project>-<environment>-web-rg when creating a group; required when reusing one."
  type        = string
  default     = null
}

variable "storage_account_name" {
  description = "Globally unique 3-24 character storage account name. Null generates a random-suffixed name."
  type        = string
  default     = null

  validation {
    condition     = var.storage_account_name == null || can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must be null or 3-24 lowercase letters and numbers."
  }
}

variable "account_replication_type" {
  description = "Storage replication type. ZRS improves zone resilience; GRS/GZRS families add cross-region copies."
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "RAGRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "account_replication_type must be LRS, ZRS, GRS, RAGRS, GZRS, or RAGZRS."
  }
}

variable "index_document" {
  description = "Default static website document."
  type        = string
  default     = "index.html"
}

variable "error_404_document" {
  description = "Static website document returned for missing content."
  type        = string
  default     = "404.html"
}

variable "enable_versioning" {
  description = "Keep historical versions of blobs."
  type        = bool
  default     = true
}

variable "blob_delete_retention_days" {
  description = "Days to retain deleted blobs and containers."
  type        = number
  default     = 7

  validation {
    condition     = var.blob_delete_retention_days >= 1 && var.blob_delete_retention_days <= 365
    error_message = "blob_delete_retention_days must be from 1 through 365."
  }
}

variable "enable_cdn" {
  description = "Create an Azure Front Door Standard profile for global HTTPS caching and routing."
  type        = bool
  default     = false
}

variable "cdn_query_string_caching_behavior" {
  description = "How Front Door incorporates query strings into its cache key."
  type        = string
  default     = "IgnoreQueryString"

  validation {
    condition     = contains(["IgnoreQueryString", "UseQueryString", "IgnoreSpecifiedQueryStrings", "IncludeSpecifiedQueryStrings"], var.cdn_query_string_caching_behavior)
    error_message = "cdn_query_string_caching_behavior must be supported by Azure Front Door."
  }
}

variable "enable_shared_access_key" {
  description = "Allow storage account shared-key authentication. Disable after confirming deployment tooling uses Microsoft Entra ID."
  type        = bool
  default     = true
}

variable "create_sample_content" {
  description = "Create placeholder index and 404 pages. Disable when a separate deployment process owns all content."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to merge with the standard template tags."
  type        = map(string)
  default     = {}
}
