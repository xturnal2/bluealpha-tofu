output "identity_id" {
  description = "User-assigned managed identity resource ID for attaching to Azure resources."
  value       = azurerm_user_assigned_identity.this.id
}

output "client_id" {
  description = "Application/client ID used to select this identity in Azure SDK configuration."
  value       = azurerm_user_assigned_identity.this.client_id
}

output "principal_id" {
  description = "Service principal object ID used for Azure RBAC assignments."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "tenant_id" {
  description = "Microsoft Entra tenant ID owning the identity."
  value       = azurerm_user_assigned_identity.this.tenant_id
}

output "federated_credential_ids" {
  description = "Federated identity credential IDs keyed by name."
  value       = { for name, credential in azurerm_federated_identity_credential.this : name => credential.id }
}

output "resource_group_name" {
  description = "Resource group containing the identity."
  value       = local.resource_group_name
}
