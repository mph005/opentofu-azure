# Azure Infrastructure with OpenTofu & Terragrunt

This repository contains OpenTofu code managed with Terragrunt for Azure infrastructure. The code is organized into reusable modules and environment-specific configurations.

## Project Structure

```text
├── environments/        # Legacy environment-specific configurations (direct module use)
│   ├── dev/             # Development environment
│   ├── staging/         # Staging environment
│   └── prod/            # Production environment
├── modules/             # Reusable modules
│   ├── compute/         # VM and compute resources
│   ├── networking/      # VNet, subnet, NSG resources
│   ├── resource_group/  # Resource group module
│   └── storage/         # Storage account and container resources
├── terragrunt/          # Terragrunt configurations
│   ├── terragrunt.hcl   # Root configuration
│   ├── dev/             # Development environment
│   ├── staging/         # Staging environment
│   └── prod/            # Production environment
├── test/                # Terratest tests
│   ├── resource_group_test.go
│   ├── networking_test.go
│   ├── storage_test.go
│   └── README.md
├── docs/                # Project documentation
│   ├── technical.md     # Technical specifications and patterns
│   ├── architecture.md  # Architecture overview and design
│   ├── security.md      # Security practices and guidelines
│   ├── status.md        # Project status and progress tracking
│   ├── tasks.md         # Development tasks and roadmap
│   └── diagrams/        # Architecture diagrams
├── main.tf              # Root module configuration
├── variables.tf         # Root variables
└── outputs.tf           # Root outputs
```

> **Note on HCL Syntax**: While we use OpenTofu, we still use `terraform` as the configuration block name in `.tf` files for compatibility with existing tools, linters, and syntax highlighters. OpenTofu is fully compatible with this naming convention. In Terragrunt files, we've updated the generated content to use `tofu` blocks.

## Prerequisites

1. [OpenTofu](https://opentofu.org/docs/intro/install/) (>= 1.0)
2. [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) (>= 0.45.0)
3. [Go](https://golang.org/doc/install) (for running Terratest)
4. Azure CLI
5. Azure Storage Account for state management (recommended)

## Getting Started

### Authentication

Before running OpenTofu and Terragrunt commands, authenticate with Azure:

```bash
az login
```

Alternatively, use a service principal:

```bash
az ad sp create-for-rbac --name "OpenTofuSP" --role Contributor --scopes /subscriptions/<subscription-id>
```

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
```

### Using Terragrunt

Terragrunt provides a thin wrapper for OpenTofu that enables DRY configurations, dependencies between modules, and easier management of environment-specific settings.

#### Initialize and Apply

```bash
# Go to the desired environment and module
cd terragrunt/dev/resource_group

# Initialize and apply
terragrunt init
terragrunt plan
terragrunt apply
```

#### Working with All Modules

Terragrunt allows you to run commands on all modules in an environment:

```bash
# Go to the environment directory
cd terragrunt/dev

# Initialize all modules
terragrunt run-all init

# Plan all modules
terragrunt run-all plan

# Apply all modules
terragrunt run-all apply
```

### Module Usage (Direct, without Terragrunt)

#### Resource Group

```hcl
module "resource_group" {
  source = "./modules/resource_group"
  
  resource_group_name = "example-rg"
  location            = "East US"
  tags                = { Environment = "Dev" }
}
```

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
```

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
```

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
```

## Testing with Terratest

This project uses [Terratest](https://terratest.gruntwork.io/) to test the infrastructure code.

### Running Tests

```bash
# Navigate to the test directory
cd test

# Download dependencies
go mod download

# Run all tests
go test -v ./...

# Run specific test
go test -v -run TestResourceGroup
```

### Test Structure

The tests verify that resources are created correctly with the expected properties:

- `resource_group_test.go`: Tests for the resource group module
- `networking_test.go`: Tests for the networking module
- `storage_test.go`: Tests for the storage module

### Advanced Testing Features

The test suite includes comprehensive validation for:

- Resource existence and properties
- Security configurations
- Network rules and access controls
- Tag compliance

For more details on the testing approach, see `docs/technical.md`.

## Terragrunt Benefits

Terragrunt enhances the OpenTofu workflow by providing:

1. **DRY configurations**: Reuse common settings across environments
2. **Dependencies**: Define explicit dependencies between modules
3. **Remote state management**: Simplified backend configuration
4. **Multi-environment support**: Easily work with dev, staging, and production
5. **Terragrunt hooks**: Run custom scripts before/after OpenTofu commands

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

## Documentation

Comprehensive documentation is available in the `docs/` directory:

- `technical.md`: Technical specifications, coding standards, and established patterns
- `architecture.md`: Architecture overview, component relationships, and diagrams
- `security.md`: Security practices, guidelines, and compliance controls
- `status.md`: Current project status and progress tracking
- `tasks.md`: Development tasks, requirements, and acceptance criteria
- `diagrams/`: Visual representations of the architecture and workflows
