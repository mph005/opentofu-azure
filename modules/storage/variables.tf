variable "name" {
  description = "The name of the storage account"
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

variable "account_tier" {
  description = "The tier of the storage account (Standard or Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "The account_tier must be either 'Standard' or 'Premium'."
  }
}

variable "replication_type" {
  description = "The replication type for the storage account"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.replication_type)
    error_message = "The replication_type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "access_tier" {
  description = "The access tier for the storage account (Hot or Cool)"
  type        = string
  default     = "Hot"

  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "The access_tier must be either 'Hot' or 'Cool'."
  }
}

variable "allow_public_access" {
  description = "Allow or disallow public access to all blobs or containers in the storage account"
  type        = bool
  default     = false
}

variable "container_soft_delete_retention_days" {
  description = "The number of days that deleted containers should be retained (0 to disable)"
  type        = number
  default     = 7

  validation {
    condition     = var.container_soft_delete_retention_days >= 0 && var.container_soft_delete_retention_days <= 365
    error_message = "The container_soft_delete_retention_days must be between 0 and 365 days."
  }
}

variable "blob_soft_delete_retention_days" {
  description = "The number of days that deleted blobs should be retained (0 to disable)"
  type        = number
  default     = 7

  validation {
    condition     = var.blob_soft_delete_retention_days >= 0 && var.blob_soft_delete_retention_days <= 365
    error_message = "The blob_soft_delete_retention_days must be between 0 and 365 days."
  }
}

variable "enable_versioning" {
  description = "Enable versioning for this storage account"
  type        = bool
  default     = false
}

variable "containers" {
  description = "Map of storage containers to create"
  type = map(object({
    access_type = string
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.containers : contains(["private", "blob", "container"], v.access_type)])
    error_message = "Access type must be one of: private, blob, container."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
} 