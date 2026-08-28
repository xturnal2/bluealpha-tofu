locals {
  alarm_name = coalesce(var.alarm_name, "${var.project_name}-${var.environment}-${lower(var.metric_name)}")
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "aws/cloudwatch-metric-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "this" {
  alarm_name          = local.alarm_name
  alarm_description   = var.alarm_description
  namespace           = var.namespace
  metric_name         = var.metric_name
  dimensions          = var.dimensions
  statistic           = var.statistic
  unit                = var.unit
  period              = var.period_seconds
  evaluation_periods  = var.evaluation_periods
  datapoints_to_alarm = var.datapoints_to_alarm
  comparison_operator = var.comparison_operator
  threshold           = var.threshold
  treat_missing_data  = var.treat_missing_data
  actions_enabled     = var.actions_enabled

  alarm_actions             = var.alarm_action_arns
  ok_actions                = var.ok_action_arns
  insufficient_data_actions = var.insufficient_data_action_arns
  tags                      = local.common_tags

  lifecycle {
    precondition {
      condition     = var.datapoints_to_alarm <= var.evaluation_periods
      error_message = "datapoints_to_alarm cannot exceed evaluation_periods."
    }
  }
}
