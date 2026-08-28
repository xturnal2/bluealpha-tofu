locals {
  dashboard_name = coalesce(var.dashboard_name, "${var.project_name}-${var.environment}-operations")

  metric_widgets = [for key in sort(keys(var.metric_widgets)) : {
    type   = "metric"
    x      = var.metric_widgets[key].x
    y      = var.metric_widgets[key].y
    width  = var.metric_widgets[key].width
    height = var.metric_widgets[key].height
    properties = merge({
      title   = var.metric_widgets[key].title
      region  = coalesce(var.metric_widgets[key].region, var.aws_region)
      view    = var.metric_widgets[key].view
      stacked = var.metric_widgets[key].stacked
      period  = var.metric_widgets[key].period_seconds
      stat    = var.metric_widgets[key].statistic
      metrics = [concat(
        [var.metric_widgets[key].namespace, var.metric_widgets[key].metric_name],
        flatten([for dimension in sort(keys(var.metric_widgets[key].dimensions)) : [dimension, var.metric_widgets[key].dimensions[dimension]]])
      )]
      }, length(var.metric_widgets[key].horizontal_annotations) == 0 ? {} : {
      annotations = {
        horizontal = [for annotation in var.metric_widgets[key].horizontal_annotations : {
          label = annotation.label
          value = annotation.value
          color = annotation.color
        }]
      }
    })
  }]

  text_widgets = [for key in sort(keys(var.text_widgets)) : {
    type   = "text"
    x      = var.text_widgets[key].x
    y      = var.text_widgets[key].y
    width  = var.text_widgets[key].width
    height = var.text_widgets[key].height
    properties = {
      markdown   = var.text_widgets[key].markdown
      background = var.text_widgets[key].background
    }
  }]
}

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = local.dashboard_name
  dashboard_body = jsonencode({
    start          = var.default_time_range
    periodOverride = var.period_override
    widgets        = concat(local.text_widgets, local.metric_widgets)
  })

  lifecycle {
    precondition {
      condition     = length(local.text_widgets) + length(local.metric_widgets) > 0
      error_message = "At least one text or metric widget is required."
    }
  }
}
