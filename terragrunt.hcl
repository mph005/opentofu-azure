# Root terragrunt.hcl configuration
# This is the root configuration that all environments will inherit from

locals {
  # Parse the file path we're in to extract the environment name
  env_path             = path_relative_to_include()
  env                  = element(split("/", local.env_path), 0)
  
  # Load environment-specific variables
  environment_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  subscription_id      = local.environment_vars.locals.subscription_id
  location             = local.environment_vars.locals.location
  resource_group_prefix = local.environment_vars.locals.resource_group_prefix
}

# Generate Azure provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
tofu {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
  subscription_id = "${local.subscription_id}"
}
EOF
}

# Configure Terragrunt to use Azure storage for the OpenTofu state
remote_state {
  backend = "azurerm"
  config = {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstate${get_env("TF_VAR_state_sa_suffix", "12345")}"
    container_name       = "tfstate"
    key                  = "${local.env}/${path_relative_to_include()}/tofu.tfstate"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Default inputs available to all modules
inputs = {
  environment = local.env
  location    = local.location
  resource_group_prefix = local.resource_group_prefix
  
  tags = {
    Environment = local.env
    ManagedBy   = "Terragrunt"
    Project     = "InfrastructureAsCode"
  }
} 