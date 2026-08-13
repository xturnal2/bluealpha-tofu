aws_region   = "us-east-1"
project_name = "example-api"
environment  = "dev"

versioning_enabled      = true
force_destroy           = false
enable_lifecycle_policy = true

abort_incomplete_multipart_upload_days = 7
noncurrent_version_expiration_days     = 90
object_expiration_days                 = null

allowed_reader_principal_arns = []
allowed_writer_principal_arns = []

tags = {
  Owner      = "platform-team"
  CostCenter = "shared-services"
}
