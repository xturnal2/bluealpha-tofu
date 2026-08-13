variable "subscription_id" {
  description = "Azure subscription ID used by the provider."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a UUID."
  }
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

variable "create_resource_group" {
  description = "Create a dedicated resource group for the DNS zone."
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Existing resource group name when create_resource_group is false."
  type        = string
  default     = null
}

variable "resource_group_location" {
  description = "Azure region recorded on the resource group. Azure public DNS zones are global resources."
  type        = string
  default     = "eastus"
}

variable "zone_name" {
  description = "Public DNS zone name, with or without a trailing dot."
  type        = string

  validation {
    condition     = length(var.zone_name) <= 254 && can(regex("^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*\\.?$", var.zone_name))
    error_message = "zone_name must be a valid DNS name no longer than 254 characters."
  }
}

variable "soa_record" {
  description = "Optional custom start-of-authority timings. Leave null to use Azure defaults."
  type = object({
    email         = string
    expire_time   = optional(number, 2419200)
    minimum_ttl   = optional(number, 300)
    refresh_time  = optional(number, 3600)
    retry_time    = optional(number, 300)
    serial_number = optional(number, 1)
    ttl           = optional(number, 3600)
  })
  default = null

  validation {
    condition = var.soa_record == null || (
      length(trimspace(var.soa_record.email)) > 0 &&
      var.soa_record.expire_time >= 0 &&
      var.soa_record.minimum_ttl >= 0 &&
      var.soa_record.refresh_time >= 0 &&
      var.soa_record.retry_time >= 0 &&
      var.soa_record.serial_number >= 0 &&
      var.soa_record.ttl >= 0
    )
    error_message = "soa_record requires an email and non-negative timing and serial values."
  }
}

variable "a_records" {
  description = "IPv4 records keyed by a stable label. Supply addresses or an Azure target resource ID, never both."
  type = map(object({
    name               = string
    ttl                = optional(number, 300)
    records            = optional(set(string), [])
    target_resource_id = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for record in values(var.a_records) :
      length(trimspace(record.name)) > 0 &&
      record.ttl >= 0 && floor(record.ttl) == record.ttl &&
      ((length(record.records) > 0) != (record.target_resource_id != null)) &&
      alltrue([for address in record.records : can(cidrhost("${address}/32", 0)) && strcontains(address, ".")]) &&
      (record.target_resource_id == null || startswith(record.target_resource_id, "/subscriptions/"))
    ])
    error_message = "Each A record needs a name, integer TTL, and exactly one of IPv4 addresses or target_resource_id."
  }
}

variable "aaaa_records" {
  description = "IPv6 records keyed by a stable label. Supply addresses or an Azure target resource ID, never both."
  type = map(object({
    name               = string
    ttl                = optional(number, 300)
    records            = optional(set(string), [])
    target_resource_id = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for record in values(var.aaaa_records) :
      length(trimspace(record.name)) > 0 &&
      record.ttl >= 0 && floor(record.ttl) == record.ttl &&
      ((length(record.records) > 0) != (record.target_resource_id != null)) &&
      alltrue([for address in record.records : can(cidrhost("${address}/128", 0)) && strcontains(address, ":")]) &&
      (record.target_resource_id == null || startswith(record.target_resource_id, "/subscriptions/"))
    ])
    error_message = "Each AAAA record needs a name, integer TTL, and exactly one of IPv6 addresses or target_resource_id."
  }
}

variable "cname_records" {
  description = "CNAME records keyed by a stable label. Supply a DNS target or Azure target resource ID, never both."
  type = map(object({
    name               = string
    ttl                = optional(number, 300)
    record             = optional(string, null)
    target_resource_id = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for record in values(var.cname_records) :
      length(trimspace(record.name)) > 0 &&
      record.name != "@" &&
      record.ttl >= 0 && floor(record.ttl) == record.ttl &&
      ((record.record != null) != (record.target_resource_id != null)) &&
      (record.record == null || length(trimspace(record.record)) > 0) &&
      (record.target_resource_id == null || startswith(record.target_resource_id, "/subscriptions/"))
    ])
    error_message = "Each CNAME needs a non-apex name, integer TTL, and exactly one of record or target_resource_id."
  }
}

variable "txt_records" {
  description = "TXT records keyed by a stable label. Values are plain strings; do not add DNS presentation quotes."
  type = map(object({
    name   = string
    ttl    = optional(number, 300)
    values = set(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for record in values(var.txt_records) :
      length(trimspace(record.name)) > 0 &&
      record.ttl >= 0 && floor(record.ttl) == record.ttl &&
      length(record.values) > 0 &&
      alltrue([for value in record.values : length(value) > 0])
    ])
    error_message = "Each TXT record requires a name, integer TTL, and at least one non-empty value."
  }
}

variable "role_assignments" {
  description = "DNS-zone-scoped Azure RBAC assignments keyed by stable label."
  type = map(object({
    principal_id   = string
    role           = string
    principal_type = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for assignment in values(var.role_assignments) :
      length(trimspace(assignment.principal_id)) > 0 &&
      length(trimspace(assignment.role)) > 0 &&
      (assignment.principal_type == null || contains(["Group", "ServicePrincipal", "User"], assignment.principal_type))
    ])
    error_message = "Each role assignment requires a principal ID and role; principal_type may be Group, ServicePrincipal, User, or null."
  }
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
