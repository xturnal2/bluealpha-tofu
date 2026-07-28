variable "project_name" {
  description = "Short project identifier used in resource names and tags."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,22}[a-z0-9]$", var.project_name))
    error_message = "project_name must be 3-24 lowercase letters, numbers, or hyphens, starting with a letter and ending with a letter or number."
  }
}

variable "environment" {
  description = "Deployment environment, such as dev, test, stage, or prod."
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,14}[a-z0-9]$", var.environment))
    error_message = "environment must be 3-16 lowercase letters, numbers, or hyphens, starting with a letter and ending with a letter or number."
  }
}

variable "aws_region" {
  description = "AWS region for S3 resources. CloudFront is global."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]$", var.aws_region))
    error_message = "aws_region must look like us-east-1."
  }
}

variable "site_bucket_name" {
  description = "Globally unique S3 origin bucket name. Null generates a deterministic account-specific name."
  type        = string
  default     = null

  validation {
    condition = var.site_bucket_name == null || (
      can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.site_bucket_name)) &&
      !strcontains(var.site_bucket_name, "..")
    )
    error_message = "site_bucket_name must be null or a valid 3-63 character S3 bucket name."
  }
}

variable "index_document" {
  description = "Default object returned for root requests."
  type        = string
  default     = "index.html"

  validation {
    condition     = length(trimspace(var.index_document)) > 0 && !startswith(var.index_document, "/")
    error_message = "index_document must be a non-empty object key without a leading slash."
  }
}

variable "aliases" {
  description = "Custom DNS names for CloudFront. These require an ACM certificate in us-east-1 and external DNS records."
  type        = list(string)
  default     = []

  validation {
    condition     = length(distinct(var.aliases)) == length(var.aliases)
    error_message = "aliases must not contain duplicate DNS names."
  }
}

variable "acm_certificate_arn" {
  description = "ARN of an ACM certificate in us-east-1 covering every alias. Required when aliases is non-empty."
  type        = string
  default     = null
}

variable "web_acl_id" {
  description = "Optional AWS WAFv2 web ACL ARN associated with the CloudFront distribution."
  type        = string
  default     = null
}

variable "price_class" {
  description = "CloudFront edge-location price class."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "price_class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "enable_ipv6" {
  description = "Enable IPv6 on the CloudFront distribution."
  type        = bool
  default     = true
}

variable "enable_versioning" {
  description = "Keep historical versions of site objects in S3."
  type        = bool
  default     = true
}

variable "noncurrent_version_expiration_days" {
  description = "Delete noncurrent object versions after this many days. Zero retains them indefinitely."
  type        = number
  default     = 30

  validation {
    condition     = var.noncurrent_version_expiration_days == 0 || var.noncurrent_version_expiration_days >= 1
    error_message = "noncurrent_version_expiration_days must be zero or at least 1."
  }
}

variable "enable_access_logging" {
  description = "Store CloudFront standard access logs in a dedicated S3 bucket."
  type        = bool
  default     = false
}

variable "log_bucket_name" {
  description = "Globally unique access-log bucket name. Null generates a deterministic account-specific name."
  type        = string
  default     = null

  validation {
    condition = var.log_bucket_name == null || (
      can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.log_bucket_name)) &&
      !strcontains(var.log_bucket_name, "..")
    )
    error_message = "log_bucket_name must be null or a valid 3-63 character S3 bucket name."
  }
}

variable "log_bucket_region" {
  description = "AWS region for the access-log bucket. CloudFront standard logging supports only selected S3 regions."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]$", var.log_bucket_region))
    error_message = "log_bucket_region must look like us-east-1."
  }
}

variable "log_retention_days" {
  description = "Days after which CloudFront access log objects are deleted."
  type        = number
  default     = 90

  validation {
    condition     = var.log_retention_days >= 1
    error_message = "log_retention_days must be at least 1."
  }
}

variable "enable_spa_fallback" {
  description = "Return index_document with HTTP 200 for S3 403 and 404 responses, useful for client-side routers."
  type        = bool
  default     = false
}

variable "forward_query_strings" {
  description = "Include all query strings in the CloudFront cache key and forward them to S3."
  type        = bool
  default     = false
}

variable "cache_min_ttl_seconds" {
  description = "Minimum CloudFront cache lifetime."
  type        = number
  default     = 0

  validation {
    condition     = var.cache_min_ttl_seconds >= 0
    error_message = "cache_min_ttl_seconds must be zero or greater."
  }
}

variable "cache_default_ttl_seconds" {
  description = "Default CloudFront cache lifetime."
  type        = number
  default     = 3600

  validation {
    condition     = var.cache_default_ttl_seconds >= 0
    error_message = "cache_default_ttl_seconds must be zero or greater."
  }
}

variable "cache_max_ttl_seconds" {
  description = "Maximum CloudFront cache lifetime."
  type        = number
  default     = 31536000

  validation {
    condition     = var.cache_max_ttl_seconds >= 0
    error_message = "cache_max_ttl_seconds must be zero or greater."
  }
}

variable "create_sample_content" {
  description = "Create a small placeholder index object. Disable when a separate deployment process owns all site content."
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Allow OpenTofu to delete non-empty site and log buckets during destroy. Use carefully."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to merge with the standard template tags."
  type        = map(string)
  default     = {}
}
