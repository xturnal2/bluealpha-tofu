locals {
  name_prefix         = "${var.project_name}-${var.environment}"
  resource_group_name = coalesce(var.resource_group_name, "${local.name_prefix}-apps-rg")
  valid_memory = {
    "0.25" = "0.5Gi"
    "0.5"  = "1Gi"
    "0.75" = "1.5Gi"
    "1"    = "2Gi"
    "1.25" = "2.5Gi"
    "1.5"  = "3Gi"
    "1.75" = "3.5Gi"
    "2"    = "4Gi"
  }

  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "azure-container-apps"
  }, var.tags)
}

resource "azurerm_resource_group" "this" {
  count = var.create_resource_group ? 1 : 0

  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "${local.name_prefix}-logs"
  location            = var.location
  resource_group_name = local.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = local.common_tags

  depends_on = [azurerm_resource_group.this]
}

resource "azurerm_container_app_environment" "this" {
  name                           = "${local.name_prefix}-cae"
  location                       = var.location
  resource_group_name            = local.resource_group_name
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.this.id
  infrastructure_subnet_id       = var.infrastructure_subnet_id
  internal_load_balancer_enabled = var.internal_load_balancer_enabled
  zone_redundancy_enabled        = var.zone_redundancy_enabled
  tags                           = local.common_tags

  lifecycle {
    precondition {
      condition     = var.create_resource_group || var.resource_group_name != null
      error_message = "resource_group_name is required when create_resource_group is false."
    }
    precondition {
      condition     = (!var.internal_load_balancer_enabled && !var.zone_redundancy_enabled) || var.infrastructure_subnet_id != null
      error_message = "infrastructure_subnet_id is required for an internal load balancer or zone redundancy."
    }
  }
}

resource "azurerm_container_app" "this" {
  name                         = "${local.name_prefix}-app"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = local.resource_group_name
  revision_mode                = var.revision_mode
  tags                         = local.common_tags

  identity {
    type = "SystemAssigned"
  }

  dynamic "secret" {
    for_each = toset(keys(nonsensitive(var.secrets)))
    content {
      name  = secret.value
      value = var.secrets[secret.value]
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "app"
      image  = var.container_image
      cpu    = var.container_cpu
      memory = var.container_memory

      dynamic "env" {
        for_each = var.environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.secret_environment_variables
        content {
          name        = env.key
          secret_name = env.value
        }
      }
    }

    dynamic "http_scale_rule" {
      for_each = var.enable_ingress && var.ingress_transport != "tcp" ? [1] : []
      content {
        name                = "http-concurrency"
        concurrent_requests = var.http_scale_concurrent_requests
      }
    }
  }

  dynamic "ingress" {
    for_each = var.enable_ingress ? [1] : []
    content {
      external_enabled           = var.external_ingress_enabled
      allow_insecure_connections = false
      target_port                = var.container_port
      transport                  = var.ingress_transport

      traffic_weight {
        percentage      = 100
        latest_revision = true
      }

      dynamic "ip_security_restriction" {
        for_each = var.ingress_ip_restrictions
        content {
          name             = ip_security_restriction.key
          action           = ip_security_restriction.value.action
          ip_address_range = ip_security_restriction.value.cidr
          description      = ip_security_restriction.value.description
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = local.valid_memory[tostring(var.container_cpu)] == var.container_memory
      error_message = "container_memory must match container_cpu for the Consumption workload profile."
    }
    precondition {
      condition     = var.min_replicas <= var.max_replicas
      error_message = "min_replicas must not exceed max_replicas."
    }
    precondition {
      condition     = alltrue([for secret_name in values(var.secret_environment_variables) : contains(keys(var.secrets), secret_name)])
      error_message = "Every secret_environment_variables value must reference a key in secrets."
    }
    precondition {
      condition     = var.enable_ingress || length(var.ingress_ip_restrictions) == 0
      error_message = "ingress_ip_restrictions requires enable_ingress."
    }
  }
}
