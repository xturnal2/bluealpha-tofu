subscription_id = "00000000-0000-0000-0000-000000000000"
project_name    = "example-app"
environment     = "dev"
short_name      = "example"

email_receivers = {
  platform_team = {
    email_address = "platform-alerts@example.com"
  }
}

# webhook_receivers = {
#   incident_router = {
#     service_uri = "https://alerts.example.com/azure"
#   }
# }

tags = { Owner = "platform-team" }
