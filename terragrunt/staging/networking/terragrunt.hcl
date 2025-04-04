# Include the root terragrunt.hcl configuration
include {
  path = find_in_parent_folders()
}

# Reference the networking module
terraform {
  source = "../../../modules/networking"
}

# Dependency on resource group
dependency "resource_group" {
  config_path = "../resource_group"
}

# Configure module-specific inputs
inputs = {
  name                = "vnet-stg"
  resource_group_name = dependency.resource_group.outputs.name
  address_space       = ["10.1.0.0/16"]
  
  subnets = {
    "snet-app" = {
      address_prefix    = "10.1.1.0/24"
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
    "snet-db" = {
      address_prefix = "10.1.2.0/24"
    }
  }

  create_network_security_group = true
  subnet_nsg_associations = {
    "snet-app" = "snet-app"
    "snet-db"  = "snet-db"
  }
  
  # Additional inputs specific to staging environment
  dns_servers = null
} 