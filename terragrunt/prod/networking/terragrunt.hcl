# Include the root terragrunt.hcl configuration
include {
  path = find_in_parent_folders()
}

# Reference the networking module
terraform {
  source = "../../../modules/networking"
}

dependency "resource_group" {
  config_path = "../resource_group"
}

# Configure module-specific inputs
inputs = {
  name                = "vnet-prod"
  resource_group_name = dependency.resource_group.outputs.name
  address_space       = ["10.2.0.0/16"]
  
  subnets = {
    "snet-app" = {
      address_prefix    = "10.2.1.0/24"
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
    "snet-db" = {
      address_prefix = "10.2.2.0/24"
    }
    "snet-mgmt" = {
      address_prefix = "10.2.3.0/24"
    }
  }

  create_network_security_group = true
  subnet_nsg_associations = {
    "snet-app"  = "snet-app"
    "snet-db"   = "snet-db"
    "snet-mgmt" = "snet-mgmt"
  }
  
  # Additional inputs specific to production environment
  dns_servers = ["168.63.129.16"] # Azure DNS
} 