locals {
  name_prefix         = "${var.project_name}-${var.environment}"
  resource_group_name = coalesce(var.resource_group_name, "${local.name_prefix}-dns-rg")
  zone_name           = trimsuffix(lower(var.zone_name), ".")

  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "azure/dns-zone"
  }, var.tags)
}

resource "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 1 : 0

  name     = local.resource_group_name
  location = var.resource_group_location
  tags     = local.common_tags
}

resource "azurerm_dns_zone" "this" {
  name                = local.zone_name
  resource_group_name = local.resource_group_name
  tags                = local.common_tags

  dynamic "soa_record" {
    for_each = var.soa_record == null ? [] : [var.soa_record]

    content {
      email         = soa_record.value.email
      expire_time   = soa_record.value.expire_time
      minimum_ttl   = soa_record.value.minimum_ttl
      refresh_time  = soa_record.value.refresh_time
      retry_time    = soa_record.value.retry_time
      serial_number = soa_record.value.serial_number
      ttl           = soa_record.value.ttl
      tags          = local.common_tags
    }
  }

  depends_on = [azurerm_resource_group.this]

  lifecycle {
    precondition {
      condition     = var.create_resource_group || var.resource_group_name != null
      error_message = "resource_group_name is required when create_resource_group is false."
    }
  }
}

resource "azurerm_dns_a_record" "this" {
  for_each = var.a_records

  name                = each.value.name
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = local.resource_group_name
  ttl                 = each.value.ttl
  records             = length(each.value.records) > 0 ? each.value.records : null
  target_resource_id  = each.value.target_resource_id
  tags                = local.common_tags
}

resource "azurerm_dns_aaaa_record" "this" {
  for_each = var.aaaa_records

  name                = each.value.name
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = local.resource_group_name
  ttl                 = each.value.ttl
  records             = length(each.value.records) > 0 ? each.value.records : null
  target_resource_id  = each.value.target_resource_id
  tags                = local.common_tags
}

resource "azurerm_dns_cname_record" "this" {
  for_each = var.cname_records

  name                = each.value.name
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = local.resource_group_name
  ttl                 = each.value.ttl
  record              = each.value.record
  target_resource_id  = each.value.target_resource_id
  tags                = local.common_tags
}

resource "azurerm_dns_txt_record" "this" {
  for_each = var.txt_records

  name                = each.value.name
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = local.resource_group_name
  ttl                 = each.value.ttl
  tags                = local.common_tags

  dynamic "record" {
    for_each = each.value.values

    content {
      value = record.value
    }
  }
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  scope                = azurerm_dns_zone.this.id
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id
  principal_type       = each.value.principal_type
}
