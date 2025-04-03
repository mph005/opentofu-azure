variable "name" {
  description = "The name prefix for the virtual machine resources"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet where the VM will be connected"
  type        = string
}

variable "create_public_ip" {
  description = "Whether to create a public IP for the VM"
  type        = bool
  default     = false
}

variable "os_type" {
  description = "The type of OS (linux or windows)"
  type        = string
  default     = "linux"

  validation {
    condition     = contains(["linux", "windows"], var.os_type)
    error_message = "The os_type must be either 'linux' or 'windows'."
  }
}

variable "vm_size" {
  description = "The size of the VM (e.g. Standard_B2s)"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "The admin username for the VM"
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "The admin password for Windows VMs"
  type        = string
  sensitive   = true
  default     = null
}

variable "ssh_public_key" {
  description = "The SSH public key for Linux VMs"
  type        = string
  default     = ""
}

variable "os_disk_type" {
  description = "The storage account type for the OS disk"
  type        = string
  default     = "Standard_LRS"

  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS"], var.os_disk_type)
    error_message = "The os_disk_type must be one of: Standard_LRS, StandardSSD_LRS, Premium_LRS."
  }
}

variable "image_publisher" {
  description = "The publisher of the VM image"
  type        = string
  default     = "Canonical"
}

variable "image_offer" {
  description = "The offer of the VM image"
  type        = string
  default     = "UbuntuServer"
}

variable "image_sku" {
  description = "The SKU of the VM image"
  type        = string
  default     = "18.04-LTS"
}

variable "image_version" {
  description = "The version of the VM image"
  type        = string
  default     = "latest"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
} 