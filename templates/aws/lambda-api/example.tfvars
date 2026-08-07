aws_region   = "us-east-1"
project_name = "example"
environment  = "dev"

architecture    = "arm64"
memory_size     = 128
timeout_seconds = 10

environment_variables = {
  MESSAGE = "Hello from the example API"
}

# The endpoint is public. Add only the browser origins that need CORS.
cors_allowed_origins = ["https://app.example.com"]

throttle_burst_limit = 100
throttle_rate_limit  = 50
log_retention_days   = 30

tags = {
  Owner      = "platform-team"
  CostCenter = "engineering"
}
