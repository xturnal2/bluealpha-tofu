aws_region   = "us-east-1"
project_name = "example"
environment  = "dev"

create_dead_letter_queue      = true
max_receive_count             = 5
visibility_timeout_seconds    = 60
message_retention_seconds     = 345600
dead_letter_retention_seconds = 1209600
receive_wait_time_seconds     = 20

# FIFO is opt-in. Set both flags for high-throughput FIFO behavior.
fifo_queue           = false
high_throughput_fifo = false

# allowed_sns_topic_arns = ["arn:aws:sns:us-east-1:123456789012:events"]

tags = {
  Owner      = "platform-team"
  CostCenter = "engineering"
}
