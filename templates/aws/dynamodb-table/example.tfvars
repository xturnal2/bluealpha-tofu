aws_region   = "us-east-1"
project_name = "example"
environment  = "dev"

hash_key      = "id"
hash_key_type = "S"
billing_mode  = "PAY_PER_REQUEST"

deletion_protection_enabled    = true
point_in_time_recovery_enabled = true
recovery_period_in_days        = 35

ttl_enabled        = true
ttl_attribute_name = "expires_at"

stream_enabled = false

# Secondary-index keys require a scalar type declaration.
# attribute_types = {
#   status = "S"
# }
# global_secondary_indexes = {
#   by-status = {
#     hash_key        = "status"
#     projection_type = "ALL"
#   }
# }

tags = {
  Owner      = "platform-team"
  CostCenter = "engineering"
}
