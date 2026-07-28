project_name = "acme-platform"
environment  = "dev"
location     = "eastus"

vnet_address_space = ["10.20.0.0/16"]

subnets = {
  app = {
    address_prefixes  = ["10.20.1.0/24"]
    service_endpoints = ["Microsoft.Storage"]
  }

  data = {
    address_prefixes = ["10.20.2.0/24"]
  }
}

create_network_security_groups = true

# Cost flag: enable only when selected subnets need a stable outbound public IP.
enable_nat_gateway       = false
nat_gateway_subnet_names = ["app"]

tags = {
  Owner      = "platform-team"
  CostCenter = "shared-services"
}
