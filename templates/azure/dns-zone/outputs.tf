output "zone_id" {
  description = "Azure resource ID of the DNS zone."
  value       = azurerm_dns_zone.this.id
}

output "zone_name" {
  description = "Canonical DNS zone name."
  value       = azurerm_dns_zone.this.name
}

output "name_servers" {
  description = "Authoritative Azure DNS name servers for parent-zone or registrar delegation."
  value       = sort(tolist(azurerm_dns_zone.this.name_servers))
}

output "resource_group_name" {
  description = "Resource group containing the zone."
  value       = local.resource_group_name
}

output "record_fqdns" {
  description = "FQDNs of records managed by this stack, grouped by type and keyed by input label."
  value = {
    a     = { for key, record in azurerm_dns_a_record.this : key => record.fqdn }
    aaaa  = { for key, record in azurerm_dns_aaaa_record.this : key => record.fqdn }
    cname = { for key, record in azurerm_dns_cname_record.this : key => record.fqdn }
    txt   = { for key, record in azurerm_dns_txt_record.this : key => record.fqdn }
  }
}
