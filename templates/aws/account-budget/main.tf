locals {
  budget_name = coalesce(var.budget_name, "${var.project_name}-${var.environment}-cost")

  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "aws/account-budget"
  })
}

resource "aws_budgets_budget" "this" {
  name         = local.budget_name
  account_id   = var.account_id
  budget_type  = "COST"
  limit_amount = tostring(var.limit_amount)
  limit_unit   = var.currency
  time_unit    = var.time_unit
  tags         = local.common_tags

  dynamic "cost_filter" {
    for_each = var.cost_filters

    content {
      name   = cost_filter.key
      values = sort(tolist(cost_filter.value))
    }
  }

  cost_types {
    include_credit             = var.cost_types.include_credit
    include_discount           = var.cost_types.include_discount
    include_other_subscription = var.cost_types.include_other_subscription
    include_recurring          = var.cost_types.include_recurring
    include_refund             = var.cost_types.include_refund
    include_subscription       = var.cost_types.include_subscription
    include_support            = var.cost_types.include_support
    include_tax                = var.cost_types.include_tax
    include_upfront            = var.cost_types.include_upfront
    use_amortized              = var.cost_types.use_amortized
    use_blended                = var.cost_types.use_blended
  }

  dynamic "notification" {
    for_each = var.notifications

    content {
      comparison_operator        = notification.value.comparison_operator
      notification_type          = notification.value.notification_type
      threshold                  = notification.value.threshold
      threshold_type             = notification.value.threshold_type
      subscriber_email_addresses = notification.value.subscriber_email_addresses
      subscriber_sns_topic_arns  = notification.value.subscriber_sns_topic_arns
    }
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for notification in values(var.notifications) :
        length(notification.subscriber_email_addresses) + length(notification.subscriber_sns_topic_arns) > 0
      ])
      error_message = "Every budget notification requires at least one email address or SNS topic ARN."
    }
  }
}
