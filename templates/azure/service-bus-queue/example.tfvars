project_name = "example"
environment  = "dev"
location     = "eastus"

sku                = "Standard"
local_auth_enabled = false

queue_name                              = "messages"
default_message_ttl                     = "P14D"
lock_duration                           = "PT1M"
max_delivery_count                      = 10
dead_lettering_on_message_expiration    = true
requires_session                        = false
requires_duplicate_detection            = false
duplicate_detection_history_time_window = "PT10M"

# Grant managed identities or service principals queue-scoped access.
# data_plane_role_assignments = {
#   producer = {
#     principal_id = "00000000-0000-0000-0000-000000000000"
#     role         = "Azure Service Bus Data Sender"
#   }
# }

tags = {
  Owner      = "platform-team"
  CostCenter = "engineering"
}
