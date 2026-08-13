locals {
  event_bus_name = coalesce(var.event_bus_name, "${var.project_name}-${var.environment}-events")
  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "aws-eventbridge-bus"
  }, var.tags)
}

resource "aws_cloudwatch_event_bus" "this" {
  name               = local.event_bus_name
  description        = var.description
  kms_key_identifier = var.kms_key_identifier

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_queue_arn == null ? [] : [var.dead_letter_queue_arn]
    content {
      arn = dead_letter_config.value
    }
  }

  tags = local.common_tags

  lifecycle {
    precondition {
      condition     = var.kms_key_identifier != null || var.dead_letter_queue_arn == null
      error_message = "dead_letter_queue_arn is only applicable when kms_key_identifier is configured."
    }
  }
}

data "aws_iam_policy_document" "bus" {
  count = length(var.allowed_put_events_principal_arns) > 0 ? 1 : 0

  statement {
    sid       = "ExplicitEventPublishers"
    effect    = "Allow"
    actions   = ["events:PutEvents"]
    resources = [aws_cloudwatch_event_bus.this.arn]

    principals {
      type        = "AWS"
      identifiers = sort(tolist(var.allowed_put_events_principal_arns))
    }
  }
}

resource "aws_cloudwatch_event_bus_policy" "this" {
  count = length(var.allowed_put_events_principal_arns) > 0 ? 1 : 0

  event_bus_name = aws_cloudwatch_event_bus.this.name
  policy         = data.aws_iam_policy_document.bus[0].json
}

resource "aws_cloudwatch_event_archive" "this" {
  count = var.enable_archive ? 1 : 0

  name               = substr("${local.event_bus_name}-archive", 0, 48)
  description        = "Replay archive for ${local.event_bus_name}"
  event_source_arn   = aws_cloudwatch_event_bus.this.arn
  event_pattern      = length(keys(var.archive_event_pattern)) == 0 ? null : jsonencode(var.archive_event_pattern)
  kms_key_identifier = var.kms_key_identifier
  retention_days     = var.archive_retention_days
}
