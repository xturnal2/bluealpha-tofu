subscription_id = "00000000-0000-0000-0000-000000000000"
project_name    = "example-app"
environment     = "dev"

scopes = [
  "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-dev/providers/Microsoft.App/containerApps/example-api"
]

severity    = 2
frequency   = "PT5M"
window_size = "PT15M"

criteria = {
  server_errors = {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "Requests"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 5
    dimensions = {
      StatusCodeCategory = { values = ["5xx"] }
    }
  }
}

# action_groups = {
#   "/subscriptions/.../resourceGroups/.../providers/microsoft.insights/actionGroups/example" = {}
# }
