output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main[*].name
}

output "resource_group_id" {
  description = "The ID of the resource group"
  value       = azurerm_resource_group.main[*].id
}

output "location" {
  description = "The location where resources have been deployed"
  value       = var.location
} 