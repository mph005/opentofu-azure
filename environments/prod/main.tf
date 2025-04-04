terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"

  backend "azurerm" {
    # Configure during initialization
    # tofu init -backend-config="resource_group_name=tfstate" -backend-config="storage_account_name=tfstate12345" -backend-config="container_name=tfstate" -backend-config="key=prod.tofu.tfstate"
  }
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
}

locals {
  environment = "prod"
  location    = "East US"

  tags = {
    Environment = local.environment
    ManagedBy   = "OpenTofu"
    Project     = "InfrastructureAsCode"
  }
}

# Create a resource group
module "resource_group" {
  source = "../../modules/resource_group"

  resource_group_name = "rg-${local.environment}-example"
  location            = local.location
  tags                = local.tags
}

# Networking module
module "networking" {
  source = "../../modules/networking"

  name                = "vnet-${local.environment}"
  resource_group_name = module.resource_group.name
  location            = local.location
  address_space       = ["10.2.0.0/16"]

  subnets = {
    "snet-app" = {
      address_prefix    = "10.2.1.0/24"
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
    "snet-db" = {
      address_prefix = "10.2.2.0/24"
    }
  }

  create_network_security_group = true
  subnet_nsg_associations = {
    "snet-app" = "snet-app"
    "snet-db"  = "snet-db"
  }

  tags = local.tags
}

# Storage account
module "storage" {
  source = "../../modules/storage"

  name                = "st${local.environment}example01"
  resource_group_name = module.resource_group.name
  location            = local.location
  account_tier        = "Premium"
  replication_type    = "ZRS"

  containers = {
    "data" = {
      access_type = "private"
    }
    "logs" = {
      access_type = "private"
    }
  }

  enable_versioning                    = true
  blob_soft_delete_retention_days      = 30
  container_soft_delete_retention_days = 30

  tags = local.tags
} 