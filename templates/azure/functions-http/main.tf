locals {
  name_prefix         = "${var.project_name}-${var.environment}"
  resource_group_name = coalesce(var.resource_group_name, "${local.name_prefix}-functions-rg")
  function_app_name   = coalesce(var.function_app_name, "${local.name_prefix}-func-${random_string.suffix.result}")
  storage_name        = substr(replace("${var.project_name}${var.environment}fn${random_string.suffix.result}", "-", ""), 0, 24)
  worker_runtime      = var.runtime_name
  ip_default_action   = coalesce(var.ip_restriction_default_action, length(var.ip_restrictions) > 0 ? "Deny" : "Allow")

  app_settings = merge({
    FUNCTIONS_WORKER_RUNTIME = local.worker_runtime
  }, var.application_settings)

  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "azure-functions-http"
  }, var.tags)
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 1 : 0

  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_storage_account" "this" {
  name                            = local.storage_name
  resource_group_name             = local.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = var.storage_replication_type
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  tags                            = local.common_tags

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "${local.name_prefix}-functions-logs"
  location            = var.location
  resource_group_name = local.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = local.common_tags

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_application_insights" "this" {
  name                 = "${local.name_prefix}-functions-appi"
  location             = var.location
  resource_group_name  = local.resource_group_name
  workspace_id         = azurerm_log_analytics_workspace.this.id
  application_type     = "web"
  retention_in_days    = var.log_retention_days
  sampling_percentage  = var.application_insights_sampling_percentage
  daily_data_cap_in_gb = var.application_insights_daily_cap_gb
  tags                 = local.common_tags
}

resource "azurerm_service_plan" "this" {
  name                = "${local.name_prefix}-functions-plan"
  resource_group_name = local.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.plan_sku_name
  worker_count        = var.worker_count
  tags                = local.common_tags

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_linux_function_app" "this" {
  name                                           = local.function_app_name
  resource_group_name                            = local.resource_group_name
  location                                       = var.location
  service_plan_id                                = azurerm_service_plan.this.id
  storage_account_name                           = azurerm_storage_account.this.name
  storage_account_access_key                     = azurerm_storage_account.this.primary_access_key
  functions_extension_version                    = var.functions_extension_version
  app_settings                                   = local.app_settings
  https_only                                     = true
  public_network_access_enabled                  = var.public_network_access_enabled
  virtual_network_subnet_id                      = var.virtual_network_subnet_id
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  tags                                           = local.common_tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on                              = var.always_on
    app_scale_limit                        = var.maximum_instance_count
    application_insights_connection_string = azurerm_application_insights.this.connection_string
    application_insights_key               = azurerm_application_insights.this.instrumentation_key
    ftps_state                             = "Disabled"
    health_check_path                      = var.health_check_path
    http2_enabled                          = true
    ip_restriction_default_action          = local.ip_default_action
    minimum_tls_version                    = "1.2"
    pre_warmed_instance_count              = var.pre_warmed_instance_count
    remote_debugging_enabled               = false
    runtime_scale_monitoring_enabled       = true
    scm_ip_restriction_default_action      = local.ip_default_action
    scm_minimum_tls_version                = "1.2"
    scm_use_main_ip_restriction            = true
    vnet_route_all_enabled                 = var.vnet_route_all_enabled

    application_stack {
      dotnet_version              = var.runtime_name == "dotnet-isolated" ? var.runtime_version : null
      node_version                = var.runtime_name == "node" ? var.runtime_version : null
      powershell_core_version     = var.runtime_name == "powershell" ? var.runtime_version : null
      python_version              = var.runtime_name == "python" ? var.runtime_version : null
      use_dotnet_isolated_runtime = var.runtime_name == "dotnet-isolated" ? true : null
    }

    dynamic "cors" {
      for_each = length(var.cors_allowed_origins) > 0 ? [1] : []
      content {
        allowed_origins     = var.cors_allowed_origins
        support_credentials = var.cors_support_credentials
      }
    }

    dynamic "ip_restriction" {
      for_each = var.ip_restrictions
      content {
        name                      = ip_restriction.key
        action                    = ip_restriction.value.action
        priority                  = ip_restriction.value.priority
        description               = ip_restriction.value.description
        ip_address                = ip_restriction.value.ip_address
        service_tag               = ip_restriction.value.service_tag
        virtual_network_subnet_id = ip_restriction.value.virtual_network_subnet_id
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.create_resource_group || var.resource_group_name != null
      error_message = "resource_group_name is required when create_resource_group is false."
    }
    precondition {
      condition     = var.plan_sku_name != "Y1" || !var.always_on
      error_message = "always_on is not supported by the Y1 Consumption plan."
    }
    precondition {
      condition     = startswith(var.plan_sku_name, "EP") || var.pre_warmed_instance_count == null
      error_message = "pre_warmed_instance_count is only supported by Elastic Premium plans."
    }
    precondition {
      condition     = !var.vnet_route_all_enabled || var.virtual_network_subnet_id != null
      error_message = "virtual_network_subnet_id is required when vnet_route_all_enabled is true."
    }
    precondition {
      condition     = !var.cors_support_credentials || !contains(var.cors_allowed_origins, "*")
      error_message = "CORS credentials cannot be enabled when allowed origins contains *."
    }
  }
}
