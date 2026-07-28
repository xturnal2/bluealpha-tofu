output "resource_group_name" {
  description = "Name of the created or reused resource group."
  value       = local.resource_group_name
}

output "virtual_network_id" {
  description = "ID of the virtual network."
  value       = azurerm_virtual_network.this.id
}

output "virtual_network_name" {
  description = "Name of the virtual network."
  value       = azurerm_virtual_network.this.name
}

output "virtual_network_address_space" {
  description = "Address spaces assigned to the virtual network."
  value       = azurerm_virtual_network.this.address_space
}

output "subnet_ids" {
  description = "Map of subnet names to resource IDs."
  value       = { for name, subnet in azurerm_subnet.this : name => subnet.id }
}

output "subnet_address_prefixes" {
  description = "Map of subnet names to assigned address prefixes."
  value       = { for name, subnet in azurerm_subnet.this : name => subnet.address_prefixes }
}

output "network_security_group_ids" {
  description = "Map of subnet names to NSG IDs, empty when NSG creation is disabled."
  value       = { for name, nsg in azurerm_network_security_group.this : name => nsg.id }
}

output "nat_gateway_id" {
  description = "NAT Gateway ID, or null when NAT is disabled."
  value       = try(azurerm_nat_gateway.this[0].id, null)
}

output "nat_public_ip_address" {
  description = "Outbound public IP, or null when NAT is disabled."
  value       = try(azurerm_public_ip.nat[0].ip_address, null)
}
