project_name = "example"
environment  = "dev"
location     = "eastus"

# Use outputs from templates/azure/vnet. The subnet must delegate to
# Microsoft.DBforPostgreSQL/flexibleServers.
delegated_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-dev-network-rg/providers/Microsoft.Network/virtualNetworks/example-dev-vnet/subnets/database"
virtual_network_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-dev-network-rg/providers/Microsoft.Network/virtualNetworks/example-dev-vnet"

sku_name               = "B_Standard_B1ms"
storage_mb             = 32768
backup_retention_days  = 7
high_availability_mode = "Disabled"

tags = {
  Owner      = "platform-team"
  CostCenter = "engineering"
}
