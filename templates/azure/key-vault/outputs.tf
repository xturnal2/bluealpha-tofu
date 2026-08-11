output "vault_id" {
  description = "Azure Key Vault resource ID for RBAC and integrations."
  value       = azurerm_key_vault.this.id
}

output "vault_name" {
  description = "Globally unique Key Vault name."
  value       = azurerm_key_vault.this.name
}

output "vault_uri" {
  description = "Data-plane URI used by SDKs and applications."
  value       = azurerm_key_vault.this.vault_uri
}

output "tenant_id" {
  description = "Microsoft Entra tenant ID associated with the vault."
  value       = local.tenant_id
}

output "resource_group_name" {
  description = "Resource group containing the vault."
  value       = local.resource_group_name
}
