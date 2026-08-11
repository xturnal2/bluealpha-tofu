aws_region   = "us-east-1"
project_name = "example-api"
environment  = "dev"

fifo_topic                  = false
content_based_deduplication = false
kms_master_key_id           = "alias/aws/sns"
signature_version           = 2
tracing_config              = "PassThrough"

# The target SQS queue must separately allow this topic ARN to SendMessage.
subscriptions = {
  worker_queue = {
    protocol             = "sqs"
    endpoint             = "arn:aws:sqs:us-east-1:123456789012:example-worker"
    raw_message_delivery = true
    filter_policy = {
      event_type = ["order.created", "order.updated"]
    }
  }
}

allowed_publisher_principal_arns = []

tags = {
  Owner      = "platform-team"
  CostCenter = "shared-services"
}
