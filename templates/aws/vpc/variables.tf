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
  description = "AWS region in which to create the VPC."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]$", var.aws_region))
    error_message = "aws_region must look like us-east-1."
  }
}

variable "vpc_cidr" {
  description = "IPv4 CIDR assigned to the VPC. Generated subnets add four prefix bits."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr)) && can(cidrsubnet(var.vpc_cidr, 4, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR large enough to divide into generated subnets."
  }
}

variable "availability_zone_count" {
  description = "Number of available zones to use when availability_zones is empty."
  type        = number
  default     = 2

  validation {
    condition     = contains([2, 3], var.availability_zone_count)
    error_message = "availability_zone_count must be 2 or 3."
  }
}

variable "availability_zones" {
  description = "Explicit availability zones to use. Leave empty to select the first two or three available zones in the region."
  type        = list(string)
  default     = []

  validation {
    condition = (
      length(var.availability_zones) == 0 ||
      (contains([2, 3], length(var.availability_zones)) && length(distinct(var.availability_zones)) == length(var.availability_zones))
    )
    error_message = "availability_zones must be empty or contain exactly 2 or 3 unique zones."
  }
}

variable "public_subnet_cidrs" {
  description = "Optional CIDRs for public subnets, one per availability zone. Empty generates CIDRs from vpc_cidr."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "Every public_subnet_cidrs value must be a valid IPv4 CIDR."
  }
}

variable "private_subnet_cidrs" {
  description = "Optional CIDRs for private subnets, one per availability zone. Empty generates CIDRs from vpc_cidr."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.private_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "Every private_subnet_cidrs value must be a valid IPv4 CIDR."
  }
}

variable "enable_nat_gateway" {
  description = "Create NAT gateways and internet routes for private subnets. NAT gateways incur hourly and data-processing charges."
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Use one shared NAT gateway instead of one per availability zone. Cheaper, but not zone-resilient."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Send accepted and rejected VPC flow logs to CloudWatch Logs. Logging and ingestion charges apply."
  type        = bool
  default     = false
}

variable "flow_log_retention_days" {
  description = "CloudWatch retention period used when flow logs are enabled."
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.flow_log_retention_days)
    error_message = "flow_log_retention_days must be a retention value supported by CloudWatch Logs."
  }
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames for instances with public IP addresses."
  type        = bool
  default     = true
}

variable "map_public_ip_on_launch" {
  description = "Automatically assign public IPv4 addresses to instances launched in public subnets."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to merge with the standard template tags."
  type        = map(string)
  default     = {}
}
