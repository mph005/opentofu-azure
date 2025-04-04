output "id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "private_endpoint_ip" {
  description = "The private IP address of the Key Vault private endpoint (if created)"
  value       = var.private_endpoint_subnet_id != null ? azurerm_private_endpoint.main[0].private_service_connection[0].private_ip_address : null
}

output "secret_ids" {
  description = "Map of secret names to their IDs"
  value       = { for k, v in azurerm_key_vault_secret.main : k => v.id }
}

output "key_vault_reference_format" {
  description = "Reference format for secrets that can be used in other modules"
  value       = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.main.vault_uri}secrets/SECRET_NAME/)"
} 