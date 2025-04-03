# Azure Infrastructure with OpenTofu

This repository contains OpenTofu (Terraform) code for managing Azure infrastructure. The code is organized into reusable modules and environment-specific configurations.

## Project Structure

```text
├── environments/        # Environment specific configurations
│   ├── dev/             # Development environment
│   ├── staging/         # Staging environment
│   └── prod/            # Production environment
├── modules/             # Reusable modules
│   ├── compute/         # VM and compute resources
│   ├── networking/      # VNet, subnet, NSG resources
│   ├── resource_group/  # Resource group module
│   └── storage/         # Storage account and container resources
├── main.tf              # Root module configuration
├── variables.tf         # Root variables
└── outputs.tf           # Root outputs


## Prerequisites

1. [OpenTofu](https://opentofu.org/docs/intro/install/) or Terraform CLI
2. Azure CLI
3. Azure Storage Account for state management (recommended)

## Getting Started

### Authentication

Before running OpenTofu commands, authenticate with Azure:

```bash
az login


Alternatively, use a service principal:

```bash
az ad sp create-for-rbac --name "OpenTofuSP" --role Contributor --scopes /subscriptions/<subscription-id>


### Remote State Setup

Create a storage account for OpenTofu state:

```bash
# Set variables
RESOURCE_GROUP_NAME=tfstate
STORAGE_ACCOUNT_NAME=tfstate$RANDOM
CONTAINER_NAME=tfstate

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location eastus

# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

# Create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME


### Module Usage

#### Resource Group

```hcl
module "resource_group" {
  source = "./modules/resource_group"
  
  resource_group_name = "example-rg"
  location            = "East US"
  tags                = { Environment = "Dev" }
}


#### Networking

```hcl
module "networking" {
  source = "./modules/networking"
  
  name                = "example-vnet"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = ["10.0.0.0/16"]
  
  subnets = {
    "app-subnet" = {
      address_prefix = "10.0.1.0/24"
    }
    "db-subnet" = {
      address_prefix = "10.0.2.0/24"
    }
  }
  
  tags = { Environment = "Dev" }
}


#### Storage

```hcl
module "storage" {
  source = "./modules/storage"
  
  name                = "examplestorage"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  
  containers = {
    "data" = {
      access_type = "private"
    }
  }
  
  tags = { Environment = "Dev" }
}


#### Compute

```hcl
module "vm" {
  source = "./modules/compute"
  
  name                = "example-vm"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_id           = module.networking.subnet_ids["app-subnet"]
  
  os_type          = "linux"
  create_public_ip = true
  ssh_public_key   = file("~/.ssh/id_rsa.pub")
  
  tags = { Environment = "Dev" }
}


## Deployment

### Initialize OpenTofu

```bash
cd environments/dev
tofu init -backend-config="resource_group_name=tfstate" \
          -backend-config="storage_account_name=tfstate12345" \
          -backend-config="container_name=tfstate" \
          -backend-config="key=dev.tfstate"


### Deploy Resources

```bash
tofu plan -out=tfplan
tofu apply tfplan


### Destroy Resources

```bash
tofu destroy


## Best Practices

1. **State Management**: Always use remote state storage
2. **Secrets**: Use Azure Key Vault for sensitive values
3. **Naming Convention**: Follow a consistent naming convention for all resources
4. **Tagging**: Tag all resources for better organization and cost tracking
5. **Environments**: Use separate state files for each environment
6. **Module Versioning**: Reference module versions with specific tags or commits

## Security Considerations

1. **Access Control**: Implement least privilege access
2. **Network Security**: Use NSGs to restrict traffic
3. **Encryption**: Enable encryption for storage accounts
4. **Key Rotation**: Regularly rotate access keys and credentials
5. **Monitoring**: Enable diagnostic settings for all resources
