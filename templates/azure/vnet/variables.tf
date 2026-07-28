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
    error_message = "project_name must be 3-20 lowercase letters, numbers, or hyphens, starting with a letter and ending with a letter or number."
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

variable "location" {
  description = "Azure region in which to create resources."
  type        = string
  default     = "eastus"

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must not be empty."
  }
}

variable "create_resource_group" {
  description = "Create a resource group for this stack. Set false to use an existing group."
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Resource group name. Null generates <project>-<environment>-network-rg when creating a group; required when reusing one."
  type        = string
  default     = null

  validation {
    condition     = var.resource_group_name == null || (length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90 && !endswith(var.resource_group_name, "."))
    error_message = "resource_group_name must be null or 1-90 characters and must not end with a period."
  }
}

variable "vnet_address_space" {
  description = "IPv4 address spaces assigned to the virtual network."
  type        = list(string)
  default     = ["10.0.0.0/16"]

  validation {
    condition     = length(var.vnet_address_space) > 0 && alltrue([for cidr in var.vnet_address_space : can(cidrnetmask(cidr))])
    error_message = "vnet_address_space must contain at least one valid IPv4 CIDR."
  }
}

variable "dns_servers" {
  description = "Custom DNS server IPv4 addresses. Empty uses Azure-provided DNS."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for address in var.dns_servers : can(cidrhost("${address}/32", 0))])
    error_message = "Every dns_servers value must be a valid IPv4 address."
  }
}

variable "subnets" {
  description = "Subnet definitions keyed by stable subnet name."
  type = map(object({
    address_prefixes                  = list(string)
    service_endpoints                 = optional(set(string), [])
    default_outbound_access_enabled   = optional(bool, false)
    private_endpoint_network_policies = optional(string, "Enabled")
    delegations = optional(map(object({
      service_name = string
      actions      = optional(list(string), [])
    })), {})
  }))

  default = {
    app = {
      address_prefixes = ["10.0.1.0/24"]
    }
    data = {
      address_prefixes = ["10.0.2.0/24"]
    }
  }

  validation {
    condition = length(var.subnets) > 0 && alltrue(flatten([
      for subnet in values(var.subnets) : [
        length(subnet.address_prefixes) > 0,
        alltrue([for cidr in subnet.address_prefixes : can(cidrnetmask(cidr))]),
        contains(["Disabled", "Enabled", "NetworkSecurityGroupEnabled", "RouteTableEnabled"], subnet.private_endpoint_network_policies),
      ]
    ]))
    error_message = "subnets must contain at least one entry with valid IPv4 CIDRs and a supported private endpoint network policy value."
  }
}

variable "create_network_security_groups" {
  description = "Create and associate an empty Network Security Group with every subnet."
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Create a Standard NAT Gateway and static public IP for selected subnets. Hourly and data-processing charges apply."
  type        = bool
  default     = false
}

variable "nat_gateway_subnet_names" {
  description = "Subnet names associated with the optional NAT Gateway. Empty associates every subnet."
  type        = set(string)
  default     = []
}

variable "nat_gateway_zones" {
  description = "Availability zones for the NAT Gateway and public IP. Empty creates non-zonal resources; use a single supported zone to make them zonal."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.nat_gateway_zones) <= 1 && alltrue([for zone in var.nat_gateway_zones : contains(["1", "2", "3"], zone)])
    error_message = "nat_gateway_zones must be empty or contain one of: 1, 2, or 3."
  }
}

variable "nat_gateway_idle_timeout_minutes" {
  description = "TCP idle timeout for the optional NAT Gateway."
  type        = number
  default     = 10

  validation {
    condition     = var.nat_gateway_idle_timeout_minutes >= 4 && var.nat_gateway_idle_timeout_minutes <= 120
    error_message = "nat_gateway_idle_timeout_minutes must be from 4 through 120."
  }
}

variable "tags" {
  description = "Additional tags to merge with the standard template tags."
  type        = map(string)
  default     = {}
}
