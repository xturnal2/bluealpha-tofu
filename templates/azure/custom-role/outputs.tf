output "role_definition_id" {
  description = "Azure resource ID used for deterministic role assignments."
  value       = azurerm_role_definition.this.role_definition_resource_id
}

output "role_definition_uuid" {
  description = "GUID assigned to the custom role definition."
  value       = azurerm_role_definition.this.role_definition_id
}

output "role_name" {
  description = "Display name of the custom role."
  value       = azurerm_role_definition.this.name
}

output "assignment_ids" {
  description = "Role assignment resource IDs keyed by input label."
  value       = { for key, assignment in azurerm_role_assignment.this : key => assignment.id }
}
