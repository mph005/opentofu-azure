# Include the root terragrunt.hcl configuration
include {
  path = find_in_parent_folders()
}

# Reference the storage module
terraform {
  source = "../../../modules/storage"
}

# Dependencies
dependency "resource_group" {
  config_path = "../resource_group"
}

dependency "networking" {
  config_path = "../networking"
}

# Configure module-specific inputs
inputs = {
  name                = "ststgexample01"
  resource_group_name = dependency.resource_group.outputs.name
  
  containers = {
    "data" = {
      access_type = "private"
    }
    "logs" = {
      access_type = "private"
    }
  }

  # Enable versioning and soft delete for staging (required for pre-prod)
  enable_versioning                    = true
  blob_soft_delete_retention_days      = 14
  container_soft_delete_retention_days = 14
  
  # Network rules - limit to the VNet
  network_rules = {
    default_action = "Deny"
    ip_rules       = []
    virtual_network_subnet_ids = [
      dependency.networking.outputs.subnet_ids["snet-app"]
    ]
  }
} 