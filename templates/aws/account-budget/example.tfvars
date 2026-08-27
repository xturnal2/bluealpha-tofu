aws_region   = "us-east-1"
project_name = "example-app"
environment  = "dev"

limit_amount = 100
currency     = "USD"
time_unit    = "MONTHLY"

# Filters use AWS Budgets dimension names. TagKeyValue values use the
# user:TagKey$TagValue form.
cost_filters = {
  TagKeyValue = ["user:Environment$dev"]
}

notifications = {
  actual_80_percent = {
    notification_type          = "ACTUAL"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = ["platform-alerts@example.com"]
  }
  forecasted_100_percent = {
    notification_type          = "FORECASTED"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = ["platform-alerts@example.com"]
  }
}

tags = {
  Owner      = "platform-team"
  CostCenter = "shared-services"
}
