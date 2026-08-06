resource "random_string" "suffix" {
  length  = 6
  lower   = true
  numeric = true
  special = false
  upper   = false
}

locals {
  name_prefix         = "${var.project_name}-${var.environment}"
  resource_group_name = coalesce(var.resource_group_name, "${local.name_prefix}-web-rg")
  storage_name = var.storage_account_name != null ? var.storage_account_name : substr(
    "${replace(local.name_prefix, "-", "")}${random_string.suffix.result}",
    0,
    24
  )

  sample_content = {
    (var.index_document)     = <<-HTML
      <!doctype html>
      <html lang="en">
        <head><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>${var.project_name}</title></head>
        <body><main><h1>${var.project_name}</h1><p>Deployed with the BlueAlpha Azure static website template.</p></main></body>
      </html>
    HTML
    (var.error_404_document) = <<-HTML
      <!doctype html>
      <html lang="en">
        <head><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Not found</title></head>
        <body><main><h1>404</h1><p>The requested page was not found.</p></main></body>
      </html>
    HTML
  }

  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "OpenTofu"
      Project     = var.project_name
      Template    = "azure-static-website"
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

resource "azurerm_storage_account" "site" {
  name                = local.storage_name
  resource_group_name = local.resource_group_name
  location            = var.location

  account_tier                      = "Standard"
  account_replication_type          = var.account_replication_type
  account_kind                      = "StorageV2"
  access_tier                       = "Hot"
  min_tls_version                   = "TLS1_2"
  https_traffic_only_enabled        = true
  public_network_access_enabled     = true
  allow_nested_items_to_be_public   = false
  shared_access_key_enabled         = var.enable_shared_access_key
  infrastructure_encryption_enabled = true

  blob_properties {
    versioning_enabled = var.enable_versioning

    delete_retention_policy {
      days = var.blob_delete_retention_days
    }

    container_delete_retention_policy {
      days = var.blob_delete_retention_days
    }
  }

  tags = local.common_tags

  lifecycle {
    precondition {
      condition     = var.create_resource_group || var.resource_group_name != null
      error_message = "resource_group_name is required when create_resource_group is false."
    }
  }

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_storage_account_static_website" "site" {
  storage_account_id = azurerm_storage_account.site.id
  index_document     = var.index_document
  error_404_document = var.error_404_document
}

resource "azurerm_storage_blob" "sample" {
  for_each = var.create_sample_content ? local.sample_content : {}

  name                 = each.key
  storage_container_id = "${azurerm_storage_account.site.id}/blobServices/default/containers/$web"
  type                 = "Block"
  content_type         = "text/html; charset=utf-8"
  source_content       = each.value

  depends_on = [azurerm_storage_account_static_website.site]
}

resource "azurerm_cdn_frontdoor_profile" "site" {
  count = var.enable_cdn ? 1 : 0

  name                = "${local.name_prefix}-fd"
  resource_group_name = local.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"
  tags                = local.common_tags

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_cdn_frontdoor_endpoint" "site" {
  count = var.enable_cdn ? 1 : 0

  name                     = "${local.name_prefix}-${random_string.suffix.result}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.site[0].id
  enabled                  = true
  tags                     = local.common_tags
}

resource "azurerm_cdn_frontdoor_origin_group" "site" {
  count = var.enable_cdn ? 1 : 0

  name                     = "storage-static-site"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.site[0].id
  session_affinity_enabled = false

  health_probe {
    interval_in_seconds = 120
    path                = "/${var.index_document}"
    protocol            = "Https"
    request_type        = "HEAD"
  }

  load_balancing {
    additional_latency_in_milliseconds = 50
    sample_size                        = 4
    successful_samples_required        = 3
  }
}

resource "azurerm_cdn_frontdoor_origin" "site" {
  count = var.enable_cdn ? 1 : 0

  name                           = "storage-static-site"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.site[0].id
  enabled                        = true
  certificate_name_check_enabled = true
  host_name                      = azurerm_storage_account.site.primary_web_host
  origin_host_header             = azurerm_storage_account.site.primary_web_host
  http_port                      = 80
  https_port                     = 443
  priority                       = 1
  weight                         = 1000

  depends_on = [azurerm_storage_account_static_website.site]
}

resource "azurerm_cdn_frontdoor_route" "site" {
  count = var.enable_cdn ? 1 : 0

  name                          = "static-site"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.site[0].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.site[0].id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.site[0].id]
  enabled                       = true

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  link_to_default_domain = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  cache {
    compression_enabled           = true
    content_types_to_compress     = ["application/javascript", "application/json", "image/svg+xml", "text/css", "text/html", "text/javascript", "text/plain"]
    query_string_caching_behavior = var.cdn_query_string_caching_behavior
  }
}
