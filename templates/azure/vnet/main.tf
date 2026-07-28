locals {
  name_prefix         = "${var.project_name}-${var.environment}"
  resource_group_name = coalesce(var.resource_group_name, "${local.name_prefix}-network-rg")
  nat_subnet_names = var.enable_nat_gateway ? (
    length(var.nat_gateway_subnet_names) > 0 ? var.nat_gateway_subnet_names : toset(keys(var.subnets))
  ) : toset([])

  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "OpenTofu"
      Project     = var.project_name
      Template    = "azure-vnet"
    },
    var.tags
  )
}

resource "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 1 : 0

  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_virtual_network" "this" {
  name                = "${local.name_prefix}-vnet"
  location            = var.location
  resource_group_name = local.resource_group_name
  address_space       = var.vnet_address_space
  dns_servers         = var.dns_servers
  tags                = local.common_tags

  lifecycle {
    precondition {
      condition     = var.create_resource_group || var.resource_group_name != null
      error_message = "resource_group_name is required when create_resource_group is false."
    }

    precondition {
      condition     = alltrue([for name in var.nat_gateway_subnet_names : contains(keys(var.subnets), name)])
      error_message = "Every nat_gateway_subnet_names value must match a key in subnets."
    }
  }

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                              = each.key
  resource_group_name               = local.resource_group_name
  virtual_network_name              = azurerm_virtual_network.this.name
  address_prefixes                  = each.value.address_prefixes
  service_endpoints                 = each.value.service_endpoints
  default_outbound_access_enabled   = each.value.default_outbound_access_enabled
  private_endpoint_network_policies = each.value.private_endpoint_network_policies

  dynamic "delegation" {
    for_each = each.value.delegations

    content {
      name = delegation.key

      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
  }
}

resource "azurerm_network_security_group" "this" {
  for_each = var.create_network_security_groups ? var.subnets : {}

  name                = "${local.name_prefix}-${each.key}-nsg"
  location            = var.location
  resource_group_name = local.resource_group_name
  tags                = local.common_tags

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = var.create_network_security_groups ? var.subnets : {}

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}

resource "azurerm_public_ip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  name                = "${local.name_prefix}-nat-pip"
  location            = var.location
  resource_group_name = local.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.nat_gateway_zones
  tags                = local.common_tags

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_nat_gateway" "this" {
  count = var.enable_nat_gateway ? 1 : 0

  name                    = "${local.name_prefix}-nat"
  location                = var.location
  resource_group_name     = local.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = var.nat_gateway_idle_timeout_minutes
  zones                   = var.nat_gateway_zones
  tags                    = local.common_tags

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  count = var.enable_nat_gateway ? 1 : 0

  nat_gateway_id       = azurerm_nat_gateway.this[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

resource "azurerm_subnet_nat_gateway_association" "this" {
  for_each = local.nat_subnet_names

  subnet_id      = azurerm_subnet.this[each.value].id
  nat_gateway_id = azurerm_nat_gateway.this[0].id
}
