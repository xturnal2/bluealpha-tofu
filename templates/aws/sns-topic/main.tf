data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  topic_base_name = coalesce(var.topic_name, "${var.project_name}-${var.environment}-events")
  topic_name      = "${local.topic_base_name}${var.fifo_topic ? ".fifo" : ""}"

  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "aws-sns-topic"
  }, var.tags)
}

resource "aws_sns_topic" "this" {
  name                        = local.topic_name
  display_name                = var.display_name
  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.fifo_topic ? var.content_based_deduplication : false
  kms_master_key_id           = var.kms_master_key_id
  signature_version           = var.signature_version
  tracing_config              = var.tracing_config
  archive_policy = var.archive_policy_days == null ? null : jsonencode({
    MessageRetentionPeriod = var.archive_policy_days
  })
  tags = local.common_tags

  lifecycle {
    precondition {
      condition     = var.fifo_topic || !var.content_based_deduplication
      error_message = "content_based_deduplication requires fifo_topic."
    }
    precondition {
      condition     = var.fifo_topic || var.archive_policy_days == null
      error_message = "archive_policy_days requires fifo_topic."
    }
  }
}

resource "aws_sns_topic_subscription" "this" {
  for_each = var.subscriptions

  topic_arn                       = aws_sns_topic.this.arn
  protocol                        = each.value.protocol
  endpoint                        = each.value.endpoint
  raw_message_delivery            = each.value.raw_message_delivery
  filter_policy                   = each.value.filter_policy == null ? null : jsonencode(each.value.filter_policy)
  filter_policy_scope             = each.value.filter_policy == null ? null : each.value.filter_policy_scope
  redrive_policy                  = each.value.dead_letter_queue_arn == null ? null : jsonencode({ deadLetterTargetArn = each.value.dead_letter_queue_arn })
  subscription_role_arn           = each.value.subscription_role_arn
  endpoint_auto_confirms          = each.value.endpoint_auto_confirms
  confirmation_timeout_in_minutes = each.value.confirmation_timeout_in_minutes

  lifecycle {
    precondition {
      condition     = each.value.protocol == "firehose" || each.value.subscription_role_arn == null
      error_message = "subscription_role_arn is only valid for firehose subscriptions."
    }
  }
}

data "aws_iam_policy_document" "topic" {
  count = length(var.allowed_publisher_principal_arns) > 0 ? 1 : 0

  statement {
    sid    = "OwnerAdministration"
    effect = "Allow"
    actions = [
      "sns:AddPermission",
      "sns:DeleteTopic",
      "sns:GetDataProtectionPolicy",
      "sns:GetTopicAttributes",
      "sns:ListSubscriptionsByTopic",
      "sns:Publish",
      "sns:RemovePermission",
      "sns:SetDataProtectionPolicy",
      "sns:SetTopicAttributes",
      "sns:Subscribe"
    ]
    resources = [aws_sns_topic.this.arn]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid       = "ExplicitPublishers"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.this.arn]

    principals {
      type        = "AWS"
      identifiers = sort(tolist(var.allowed_publisher_principal_arns))
    }
  }
}

resource "aws_sns_topic_policy" "this" {
  count = length(var.allowed_publisher_principal_arns) > 0 ? 1 : 0

  arn    = aws_sns_topic.this.arn
  policy = data.aws_iam_policy_document.topic[0].json
}
