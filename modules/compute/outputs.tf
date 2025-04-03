output "vm_id" {
  description = "The ID of the virtual machine"
  value       = var.os_type == "linux" ? one(azurerm_linux_virtual_machine.main[*].id) : one(azurerm_windows_virtual_machine.main[*].id)
}

output "vm_name" {
  description = "The name of the virtual machine"
  value       = var.os_type == "linux" ? one(azurerm_linux_virtual_machine.main[*].name) : one(azurerm_windows_virtual_machine.main[*].name)
}

output "private_ip_address" {
  description = "The private IP address of the virtual machine"
  value       = azurerm_network_interface.main.private_ip_address
}

output "public_ip_address" {
  description = "The public IP address of the virtual machine"
  value       = var.create_public_ip ? one(azurerm_public_ip.main[*].ip_address) : null
}

output "principal_id" {
  description = "The Principal ID of the system-assigned identity of the virtual machine"
  value       = var.os_type == "linux" ? one(azurerm_linux_virtual_machine.main[*].identity[0].principal_id) : one(azurerm_windows_virtual_machine.main[*].identity[0].principal_id)
} 