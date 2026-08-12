aws_region   = "us-east-1"
project_name = "example-api"
environment  = "dev"

description             = "Runtime configuration for the example API"
recovery_window_in_days = 30

# This stack creates metadata only. Populate the value outside OpenTofu so the
# secret material is not stored in state.
allowed_reader_principal_arns = [
  "arn:aws:iam::123456789012:role/example-api-runtime"
]
allowed_writer_principal_arns = []

replica_regions = {}

tags = {
  Owner      = "platform-team"
  CostCenter = "shared-services"
}
