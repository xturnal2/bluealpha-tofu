variable "aws_region" {
  description = "AWS provider region and default region for private VPC associations."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project identifier used in tags."
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

variable "zone_name" {
  description = "DNS zone name, with or without a trailing dot."
  type        = string

  validation {
    condition     = length(var.zone_name) <= 254 && can(regex("^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*\\.?$", var.zone_name))
    error_message = "zone_name must be a valid fully qualified DNS name."
  }
}

variable "comment" {
  description = "Operational description stored with the hosted zone."
  type        = string
  default     = "Managed by OpenTofu"

  validation {
    condition     = length(var.comment) <= 256
    error_message = "comment must not exceed 256 characters."
  }
}

variable "private_zone" {
  description = "Create a private zone associated with the supplied VPCs instead of a public zone."
  type        = bool
  default     = false
}

variable "vpc_associations" {
  description = "VPCs associated at private-zone creation, keyed by a stable label. Must be empty for public zones."
  type = map(object({
    vpc_id     = string
    vpc_region = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for association in values(var.vpc_associations) :
      can(regex("^vpc-[0-9a-f]+$", association.vpc_id)) &&
      (association.vpc_region == null || length(trimspace(association.vpc_region)) > 0)
    ])
    error_message = "Each VPC association requires a VPC ID and an optional non-empty region."
  }
}

variable "delegation_set_id" {
  description = "Reusable delegation set ID for a public zone, or null for AWS-assigned name servers."
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Delete record sets not managed by this stack when destroying the zone. This can remove externally managed DNS records."
  type        = bool
  default     = false
}

variable "records" {
  description = "Non-alias DNS records keyed by a stable label. Values must use Route 53 record syntax, including quotes where TXT records require them."
  type = map(object({
    name            = string
    type            = string
    ttl             = optional(number, 300)
    values          = set(string)
    allow_overwrite = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for record in values(var.records) :
      length(trimspace(record.name)) > 0 &&
      contains(["A", "AAAA", "CAA", "CNAME", "MX", "NAPTR", "NS", "PTR", "SRV", "TXT"], upper(record.type)) &&
      record.ttl >= 0 && floor(record.ttl) == record.ttl &&
      length(record.values) > 0
    ])
    error_message = "Each record requires a name, supported type, non-negative integer TTL, and at least one value."
  }
}

variable "alias_records" {
  description = "Route 53 alias records keyed by a stable label. Use provider-specific target names and hosted zone IDs."
  type = map(object({
    name                   = string
    type                   = optional(string, "A")
    target_name            = string
    target_zone_id         = string
    evaluate_target_health = optional(bool, false)
    allow_overwrite        = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for record in values(var.alias_records) :
      length(trimspace(record.name)) > 0 &&
      contains(["A", "AAAA"], upper(record.type)) &&
      length(trimspace(record.target_name)) > 0 &&
      can(regex("^Z[A-Z0-9]+$", record.target_zone_id))
    ])
    error_message = "Each alias requires a name, A or AAAA type, target DNS name, and Route 53 target zone ID."
  }
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
