variable "key_vault_name" {
  description = "Name of the Key Vault"
  type        = string
  validation {
    condition     = length(var.key_vault_name) >= 3 && length(var.key_vault_name) <= 24
    error_message = "Key Vault name must be between 3 and 24 characters long."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
}

variable "tenant_id" {
  description = "The Azure Active Directory tenant ID"
  type        = string
}

variable "sku_name" {
  description = "The SKU name of the Key Vault (standard or premium)"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "SKU name must be either 'standard' or 'premium'."
  }
}

variable "enabled_for_disk_encryption" {
  description = "Whether Azure Disk Encryption is permitted to retrieve secrets and unwrap keys"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "The number of days that deleted keys, secrets, and certificates are retained"
  type        = number
  default     = 90
  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention days must be between 7 and 90 days."
  }
}

variable "purge_protection_enabled" {
  description = "Whether to enable purge protection"
  type        = bool
  default     = true
}

variable "enable_rbac_authorization" {
  description = "Whether to enable RBAC authorization for the Key Vault"
  type        = bool
  default     = false
}

variable "network_acls" {
  description = "Network ACLs for the Key Vault"
  type = object({
    bypass                     = string
    default_action             = string
    ip_rules                   = list(string)
    virtual_network_subnet_ids = list(string)
  })
  default = null
}

variable "access_policies" {
  description = "Access policies for the Key Vault (only used when RBAC is disabled)"
  type = map(object({
    object_id               = string
    secret_permissions      = list(string)
    key_permissions         = list(string)
    certificate_permissions = list(string)
    storage_permissions     = list(string)
  }))
  default = {}
}

variable "secrets" {
  description = "Map of secrets to create in the Key Vault"
  type = map(object({
    value        = string
    content_type = string
    tags         = map(string)
  }))
  default   = {}
  sensitive = true
}

variable "private_endpoint_subnet_id" {
  description = "The ID of the subnet where the private endpoint should be created"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "The ID of the private DNS zone for Key Vault"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
} 