locals {
  name_prefix           = "${var.project_name}-${var.environment}"
  resource_group_name   = coalesce(var.resource_group_name, "${local.name_prefix}-data-rg")
  server_name           = coalesce(var.server_name, "${local.name_prefix}-pg-${random_string.server_suffix.result}")
  private_dns_zone_name = coalesce(var.private_dns_zone_name, "${local.name_prefix}.postgres.database.azure.com")
  private_dns_zone_id   = var.create_private_dns_zone ? azurerm_private_dns_zone.this[0].id : var.private_dns_zone_id

  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "azure-postgresql-flexible"
  }, var.tags)
}

resource "random_string" "server_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "random_password" "administrator" {
  count = var.administrator_password == null ? 1 : 0

  length      = 24
  special     = false
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
}

resource "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 1 : 0

  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_private_dns_zone" "this" {
  count = var.create_private_dns_zone ? 1 : 0

  name                = local.private_dns_zone_name
  resource_group_name = local.resource_group_name
  tags                = local.common_tags

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  count = var.create_private_dns_zone ? 1 : 0

  name                  = "${local.name_prefix}-postgres-link"
  private_dns_zone_name = azurerm_private_dns_zone.this[0].name
  resource_group_name   = local.resource_group_name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
  tags                  = local.common_tags
}

resource "azurerm_postgresql_flexible_server" "this" {
  name                          = local.server_name
  resource_group_name           = local.resource_group_name
  location                      = var.location
  version                       = var.postgresql_version
  administrator_login           = var.administrator_login
  administrator_password        = var.administrator_password != null ? var.administrator_password : random_password.administrator[0].result
  delegated_subnet_id           = var.delegated_subnet_id
  private_dns_zone_id           = local.private_dns_zone_id
  public_network_access_enabled = false
  sku_name                      = var.sku_name
  storage_mb                    = var.storage_mb
  auto_grow_enabled             = var.auto_grow_enabled
  backup_retention_days         = var.backup_retention_days
  geo_redundant_backup_enabled  = var.geo_redundant_backup_enabled
  zone                          = var.availability_zone
  tags                          = local.common_tags

  dynamic "high_availability" {
    for_each = var.high_availability_mode == "Disabled" ? [] : [1]
    content {
      mode                      = var.high_availability_mode
      standby_availability_zone = var.standby_availability_zone
    }
  }

  dynamic "maintenance_window" {
    for_each = var.maintenance_window == null ? [] : [var.maintenance_window]
    content {
      day_of_week  = maintenance_window.value.day_of_week
      start_hour   = maintenance_window.value.start_hour
      start_minute = maintenance_window.value.start_minute
    }
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.this]

  lifecycle {
    precondition {
      condition     = var.create_resource_group || var.resource_group_name != null
      error_message = "resource_group_name is required when create_resource_group is false."
    }
    precondition {
      condition     = !var.create_private_dns_zone || var.virtual_network_id != null
      error_message = "virtual_network_id is required when create_private_dns_zone is true."
    }
    precondition {
      condition     = var.create_private_dns_zone || var.private_dns_zone_id != null
      error_message = "private_dns_zone_id is required when create_private_dns_zone is false."
    }
  }
}

resource "azurerm_postgresql_flexible_server_database" "this" {
  count = var.database_name == null ? 0 : 1

  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = var.database_charset
  collation = var.database_collation
}

resource "azurerm_postgresql_flexible_server_configuration" "this" {
  for_each = var.server_configurations

  name      = each.key
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = each.value
}
