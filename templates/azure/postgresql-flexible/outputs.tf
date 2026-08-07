output "resource_group_name" {
  description = "Created or reused resource group name."
  value       = local.resource_group_name
}

output "server_id" {
  description = "PostgreSQL Flexible Server resource ID."
  value       = azurerm_postgresql_flexible_server.this.id
}

output "server_name" {
  description = "PostgreSQL Flexible Server name."
  value       = azurerm_postgresql_flexible_server.this.name
}

output "fqdn" {
  description = "Private PostgreSQL server FQDN."
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "administrator_login" {
  description = "PostgreSQL administrator login."
  value       = azurerm_postgresql_flexible_server.this.administrator_login
}

output "generated_administrator_password" {
  description = "Generated administrator password, or null when one was supplied. Sensitive and stored in state."
  value       = try(random_password.administrator[0].result, null)
  sensitive   = true
}

output "database_name" {
  description = "Created application database name, or null when disabled."
  value       = try(azurerm_postgresql_flexible_server_database.this[0].name, null)
}

output "private_dns_zone_id" {
  description = "Created or reused private DNS zone ID."
  value       = local.private_dns_zone_id
}
