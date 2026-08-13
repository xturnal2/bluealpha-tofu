aws_region   = "us-east-1"
project_name = "example-app"
environment  = "dev"
zone_name    = "example.com"

private_zone  = false
force_destroy = false

records = {
  verification = {
    name   = "_service.example.com"
    type   = "TXT"
    ttl    = 300
    values = ["\"replace-with-verification-token\""]
  }
}

# alias_records = {
#   website = {
#     name           = "example.com"
#     type           = "A"
#     target_name    = "d111111abcdef8.cloudfront.net"
#     target_zone_id = "Z2FDTNDATAQYW2"
#   }
# }

tags = {
  Owner      = "platform-team"
  CostCenter = "shared-services"
}
