variable "name" {
  description = "The name prefix for the virtual network"
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

variable "address_space" {
  description = "The address space for the virtual network"
  type        = list(string)
}

variable "dns_servers" {
  description = "The DNS servers to be used with the virtual network"
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "Map of subnet objects to create"
  type = map(object({
    address_prefix    = string
    service_endpoints = optional(list(string))
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    }))
  }))
  default = {}
}

variable "create_network_security_group" {
  description = "Whether to create a network security group"
  type        = bool
  default     = true
}

variable "subnet_nsg_associations" {
  description = "Map of subnet names to associate with the NSG"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
} 