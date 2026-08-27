subscription_id = "00000000-0000-0000-0000-000000000000"
project_name    = "example-app"
environment     = "dev"

description = "Read resources and restart Container Apps without changing configuration"

actions = [
  "Microsoft.Resources/subscriptions/resourceGroups/read",
  "Microsoft.App/containerApps/read",
  "Microsoft.App/containerApps/revisions/read",
  "Microsoft.App/containerApps/revisions/restart/action"
]

not_actions      = []
data_actions     = []
not_data_actions = []

# Assign the role after confirming the exact principal and scope.
role_assignments = {
  # operators = {
  #   principal_id   = "11111111-1111-1111-1111-111111111111"
  #   principal_type = "Group"
  # }
}
