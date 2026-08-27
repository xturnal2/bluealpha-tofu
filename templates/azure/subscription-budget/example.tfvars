subscription_id = "00000000-0000-0000-0000-000000000000"
project_name    = "example-app"
environment     = "dev"

amount     = 100
time_grain = "Monthly"
start_date = "2026-09-01T00:00:00Z"

tag_filters = {
  Environment = {
    values = ["dev"]
  }
}

notifications = {
  actual_80_percent = {
    threshold_type = "Actual"
    threshold      = 80
    contact_emails = ["platform-alerts@example.com"]
  }
  forecasted_100_percent = {
    threshold_type = "Forecasted"
    threshold      = 100
    contact_emails = ["platform-alerts@example.com"]
  }
}
