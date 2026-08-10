locals {
  name_prefix     = "${var.project_name}-${var.environment}"
  queue_base_name = coalesce(var.queue_name, "${local.name_prefix}-queue")
  fifo_suffix     = var.fifo_queue ? ".fifo" : ""

  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "OpenTofu"
    Project     = var.project_name
    Template    = "aws-sqs-queue"
  }, var.tags)
}

resource "aws_sqs_queue" "dead_letter" {
  count = var.create_dead_letter_queue ? 1 : 0

  name                              = "${local.queue_base_name}-dlq${local.fifo_suffix}"
  fifo_queue                        = var.fifo_queue
  content_based_deduplication       = var.fifo_queue ? var.content_based_deduplication : null
  deduplication_scope               = var.fifo_queue ? (var.high_throughput_fifo ? "messageGroup" : "queue") : null
  fifo_throughput_limit             = var.fifo_queue ? (var.high_throughput_fifo ? "perMessageGroupId" : "perQueue") : null
  message_retention_seconds         = var.dead_letter_retention_seconds
  sqs_managed_sse_enabled           = var.kms_master_key_id == null
  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_master_key_id == null ? null : var.kms_data_key_reuse_period_seconds
  tags                              = merge(local.common_tags, { QueueRole = "dead-letter" })
}

resource "aws_sqs_queue" "this" {
  name                              = "${local.queue_base_name}${local.fifo_suffix}"
  fifo_queue                        = var.fifo_queue
  content_based_deduplication       = var.fifo_queue ? var.content_based_deduplication : null
  deduplication_scope               = var.fifo_queue ? (var.high_throughput_fifo ? "messageGroup" : "queue") : null
  fifo_throughput_limit             = var.fifo_queue ? (var.high_throughput_fifo ? "perMessageGroupId" : "perQueue") : null
  delay_seconds                     = var.delay_seconds
  max_message_size                  = var.maximum_message_size
  message_retention_seconds         = var.message_retention_seconds
  visibility_timeout_seconds        = var.visibility_timeout_seconds
  receive_wait_time_seconds         = var.receive_wait_time_seconds
  sqs_managed_sse_enabled           = var.kms_master_key_id == null
  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_master_key_id == null ? null : var.kms_data_key_reuse_period_seconds
  redrive_policy = var.create_dead_letter_queue ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter[0].arn
    maxReceiveCount     = var.max_receive_count
  }) : null
  tags = merge(local.common_tags, { QueueRole = "source" })

  lifecycle {
    precondition {
      condition     = var.fifo_queue || (!var.content_based_deduplication && !var.high_throughput_fifo)
      error_message = "content_based_deduplication and high_throughput_fifo require fifo_queue."
    }
  }
}

resource "aws_sqs_queue_redrive_allow_policy" "dead_letter" {
  count = var.create_dead_letter_queue ? 1 : 0

  queue_url = aws_sqs_queue.dead_letter[0].id
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.this.arn]
  })
}

data "aws_iam_policy_document" "sns" {
  count = length(var.allowed_sns_topic_arns) > 0 ? 1 : 0

  statement {
    sid       = "AllowConfiguredSnsTopics"
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.this.arn]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = sort(tolist(var.allowed_sns_topic_arns))
    }
  }
}

resource "aws_sqs_queue_policy" "sns" {
  count = length(var.allowed_sns_topic_arns) > 0 ? 1 : 0

  queue_url = aws_sqs_queue.this.id
  policy    = data.aws_iam_policy_document.sns[0].json
}
