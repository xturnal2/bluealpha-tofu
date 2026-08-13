subscription_id = "00000000-0000-0000-0000-000000000000"
project_name    = "example-app"
environment     = "dev"
zone_name       = "example.com"

a_records = {
  www = {
    name    = "www"
    ttl     = 300
    records = ["192.0.2.10"]
  }
}

txt_records = {
  verification = {
    name   = "_service"
    ttl    = 300
    values = ["replace-with-verification-token"]
  }
}

# cname_records = {
#   docs = {
#     name   = "docs"
#     record = "example-host.azurefd.net"
#   }
# }

role_assignments = {
  # dns_automation = {
  #   principal_id   = "11111111-1111-1111-1111-111111111111"
  #   role           = "DNS Zone Contributor"
  #   principal_type = "ServicePrincipal"
  # }
}

tags = {
  Owner      = "platform-team"
  CostCenter = "shared-services"
}
