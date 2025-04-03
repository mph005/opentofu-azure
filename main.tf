terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"

  backend "azurerm" {
    # We will configure this during initialization
    # resource_group_name  = "tfstate"
    # storage_account_name = "tfstate12345"
    # container_name       = "tfstate"
    # key                  = "terraform.tfstate"
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

# Variables
variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "The environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    managed_by = "opentofu"
  }
}

# Remote state data sources
# Uncomment when you have resources in other states you need to reference
# data "terraform_remote_state" "network" {
#   backend = "azurerm"
#   config = {
#     resource_group_name  = "tfstate"
#     storage_account_name = "tfstate12345"
#     container_name       = "tfstate"
#     key                  = "network.tfstate"
#   }
# } 