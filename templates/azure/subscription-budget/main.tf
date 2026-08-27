locals {
  budget_name = coalesce(var.budget_name, "${var.project_name}-${var.environment}-cost")
}

resource "azurerm_consumption_budget_subscription" "this" {
  name            = local.budget_name
  subscription_id = "/subscriptions/${var.subscription_id}"
  amount          = var.amount
  time_grain      = var.time_grain

  time_period {
    start_date = var.start_date
    end_date   = var.end_date
  }

  dynamic "filter" {
    for_each = length(var.dimension_filters) + length(var.tag_filters) > 0 ? [1] : []

    content {
      dynamic "dimension" {
        for_each = var.dimension_filters

        content {
          name     = dimension.key
          operator = dimension.value.operator
          values   = sort(tolist(dimension.value.values))
        }
      }

      dynamic "tag" {
        for_each = var.tag_filters

        content {
          name     = tag.key
          operator = tag.value.operator
          values   = sort(tolist(tag.value.values))
        }
      }
    }
  }

  dynamic "notification" {
    for_each = var.notifications

    content {
      enabled        = notification.value.enabled
      operator       = notification.value.operator
      threshold      = notification.value.threshold
      threshold_type = notification.value.threshold_type
      contact_emails = sort(tolist(notification.value.contact_emails))
      contact_groups = sort(tolist(notification.value.contact_groups))
      contact_roles  = sort(tolist(notification.value.contact_roles))
    }
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for notification in values(var.notifications) :
        length(notification.contact_emails) + length(notification.contact_groups) + length(notification.contact_roles) > 0
      ])
      error_message = "Every budget notification requires at least one email, action group, or contact role."
    }
  }
}
