# Technical Specifications & Standards

This document outlines the technical specifications, coding standards, and established patterns for our Azure infrastructure project.

> **Note on HCL Syntax**: For compatibility with existing tools, linters, and syntax highlighters, we use `terraform` as the block name in many `.tf` files, while using `tofu` in newer contexts like Terragrunt-generated content. OpenTofu understands both naming conventions.

## Technology Stack

| Component | Technology | Version |
|-----------|------------|---------|
| IaC Tool | OpenTofu | >= 1.0 |
| Provider | Azure RM | ~> 3.0 |
| Authentication | Azure CLI / Service Principal | Latest |
| State Backend | Azure Storage | Latest |
| Configuration Management | Terragrunt | >= 0.45.0 |
| Testing Framework | Terratest | >= 0.43.0 |
| Version Control | Git | Latest |
| CI/CD | GitHub Actions / Azure DevOps Pipelines | Latest |

## Coding Standards

### OpenTofu Standards

1. **File Organization**
   - `main.tf` - Primary resource definitions
   - `variables.tf` - Input variable declarations
   - `outputs.tf` - Output declarations
   - `versions.tf` - Provider and version constraints

2. **Naming Conventions**

   ```hcl
   # Resource Group
   resource "azurerm_resource_group" "example" {
     name     = "rg-${var.environment}-${var.project}-${var.location}"
     location = var.location
     tags     = var.tags
   }
   ```

   - Use lowercase with hyphens for resource names
   - Include environment, project, and region in names
   - Use Azure resource prefixes (e.g., `rg-` for resource groups)

3. **Variable Declarations**

   ```hcl
   variable "resource_group_name" {
     description = "Name of the resource group"
     type        = string
     validation {
       condition     = length(var.resource_group_name) <= 90
       error_message = "Resource group name cannot exceed 90 characters."
     }
   }
   ```

   - All variables must include description and type
   - Add validation rules for critical variables
   - Use specific types (string, number, bool, list, map, object)

4. **Module Standards**

   ```hcl
   module "example" {
     source = "../modules/example"
     
     # Required parameters
     required_param = "value"
     
     # Optional parameters with defaults
     optional_param = "value"
   }
   ```

   - Separate required and optional parameters
   - Sort parameters alphabetically
   - Include comments for non-obvious parameters

5. **Resource Tagging**

   ```hcl
   locals {
     common_tags = {
       Environment = var.environment
       Project     = var.project
       ManagedBy   = "OpenTofu"
       Owner       = "InfraTeam"
     }
   }
   ```

   - Apply consistent tags to all resources
   - Merge common tags with resource-specific tags

## Terragrunt Configuration

### Directory Structure

```
terragrunt/
├── terragrunt.hcl        # Root configuration
├── dev/                  # Development environment
│   ├── env.hcl           # Environment-specific variables
│   ├── resource_group/
│   │   └── terragrunt.hcl
│   ├── networking/
│   │   └── terragrunt.hcl
│   └── storage/
│       └── terragrunt.hcl
├── staging/              # Staging environment
│   ├── env.hcl
│   └── ...
└── prod/                 # Production environment
    ├── env.hcl
    └── ...
```

### Root Configuration

The root configuration (`terragrunt.hcl`) in the root directory contains common settings for all environments:

```hcl
# Generate provider configuration
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
}

provider "azurerm" {
  features {}
  subscription_id = "${local.subscription_id}"
}
EOF
}

# Configure remote state
remote_state {
  backend = "azurerm"
  config = {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstate12345"
    container_name       = "tfstate"
    key                  = "${local.env}/${path_relative_to_include()}/tofu.tfstate"
  }
}
```

### Environment Configuration

Each environment has an `env.hcl` file with environment-specific variables:

```hcl
# dev/env.hcl
locals {
  subscription_id      = "00000000-0000-0000-0000-000000000000"
  location             = "East US"
  resource_group_prefix = "rg-dev"
}
```

### Module Configuration

Each module has its own `terragrunt.hcl` file that includes the root configuration:

```hcl
# Include the root terragrunt.hcl configuration
include {
  path = find_in_parent_folders()
}

# Reference the module
tofu {
  source = "../../../modules/resource_group"
}

# Configure module-specific inputs
inputs = {
  resource_group_name = "rg-dev-example"
}
```

### Dependencies Between Modules

Terragrunt enables explicit dependencies between modules:

```hcl
include {
  path = find_in_parent_folders()
}

tofu {
  source = "../../../modules/networking"
}

# Dependency on resource group
dependency "resource_group" {
  config_path = "../resource_group"
}

inputs = {
  name                = "vnet-dev"
  resource_group_name = dependency.resource_group.outputs.name
  # ...
}
```

### Advanced Terragrunt Features

#### Locals and Helper Functions

```hcl
# Root terragrunt.hcl
locals {
  # Parse the filepath to extract environment
  path_components = split("/", path_relative_to_include())
  env             = path_components[0]
  
  # Load env-specific variables
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  
  # Common tags for all resources
  common_tags     = {
    Environment   = local.env
    ManagedBy     = "Terragrunt"
    Project       = "AzureInfra"
  }
}

# Pass common variables to all child configurations
inputs = {
  tags            = local.common_tags
  environment     = local.env
  location        = local.env_vars.locals.location
}
```

#### Generate Blocks for Consistent Configuration

```hcl
# Generate version constraints
generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
tofu {
  required_version = ">= 1.0"
}
EOF
}

# Generate backend configuration
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
tofu {
  backend "azurerm" {}
}
EOF
}
```

## Testing with Terratest

### Test Structure

Tests are organized by module in the `test/` directory:

```
test/
├── go.mod
├── go.sum
├── resource_group_test.go
├── networking_test.go
├── storage_test.go
└── README.md
```

> **Note:** Terratest uses a package called `terraform` for its Go functions, which we use despite our project using OpenTofu. This is because Terratest was created before the OpenTofu fork, but it works seamlessly with both OpenTofu and Terraform when the appropriate binary is specified. The parameter names like `TerraformDir` and `TerraformBinary` are part of the Terratest API and cannot be changed, but we specify "terragrunt" as the binary to use OpenTofu through Terragrunt.

### Test Implementation

Each test file follows this pattern:

```go
package test

import (
	"testing"
	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestModule(t *testing.T) {
	// Configure Terragrunt options
	terraformOptions := &terraform.Options{
		TerraformDir: "../terragrunt/dev/module",
		TerraformBinary: "terragrunt",
		Vars: map[string]interface{}{
			"variable": "value",
		},
	}

	// Clean up after test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy resources
	terraform.InitAndApply(t, terraformOptions)

	// Verify resources
	// ...
}
```

### Running Tests

```bash
# Run all tests
cd test/
go test -v ./...

# Run a specific test
go test -v -run TestResourceGroup
```

### Comprehensive Testing Strategies

#### Testing Resource Creation with Assertions

```go
func TestResourceGroupModule(t *testing.T) {
	// Set up Terratest
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir:    "../terragrunt/dev/resource_group",
		TerraformBinary: "terragrunt",
	})
	defer terraform.Destroy(t, terraformOptions)
	
	// Deploy and get outputs
	terraform.InitAndApply(t, terraformOptions)
	resourceGroupName := terraform.Output(t, terraformOptions, "resource_group_name")
	
	// Verify resource exists
	exists := azure.ResourceGroupExists(t, resourceGroupName, "")
	assert.True(t, exists, "Resource group should exist")
	
	// Verify tags
	tags := azure.GetResourceGroupTags(t, resourceGroupName, "")
	assert.Equal(t, "dev", tags["Environment"])
	assert.Equal(t, "OpenTofu", tags["ManagedBy"])
}
```

#### Testing Security Configurations

```go
func TestNetworkSecurityRules(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir:    "../terragrunt/dev/networking",
		TerraformBinary: "terragrunt",
	})
	defer terraform.Destroy(t, terraformOptions)
	
	// Deploy
	terraform.InitAndApply(t, terraformOptions)
	
	// Get outputs
	nsgName := terraform.Output(t, terraformOptions, "nsg_name")
	rgName := terraform.Output(t, terraformOptions, "resource_group_name")
	
	// Verify security rules
	rules := azure.GetNetworkSecurityGroupRules(t, nsgName, rgName, "")
	
	// Check if HTTPS is allowed and SSH is restricted
	httpsRuleExists := false
	sshRuleRestricted := true
	
	for _, rule := range rules {
		if rule.DestinationPortRange == "443" && rule.Access == "Allow" {
			httpsRuleExists = true
		}
		if rule.DestinationPortRange == "22" && rule.SourceAddressPrefix == "*" {
			sshRuleRestricted = false
		}
	}
	
	assert.True(t, httpsRuleExists, "HTTPS traffic should be allowed")
	assert.True(t, sshRuleRestricted, "SSH should not be open to the world")
}
```

## Established Patterns

### 1. Resource Group Pattern

Create a dedicated resource group for each logical group of resources:

```hcl
module "resource_group" {
  source = "../modules/resource_group"
  
  name     = "rg-${var.environment}-${var.purpose}"
  location = var.location
  tags     = var.tags
}
```

### 2. Networking Pattern

Create a virtual network with multiple subnets:

```hcl
module "networking" {
  source = "../modules/networking"
  
  vnet_name           = "vnet-${var.environment}"
  resource_group_name = module.resource_group.name
  address_space       = ["10.0.0.0/16"]
  
  subnets = {
    "app" = {
      address_prefix = "10.0.1.0/24"
    }
    "data" = {
      address_prefix = "10.0.2.0/24"
    }
  }
}
```

### 3. Storage Pattern

Create storage accounts with multiple containers:

```hcl
module "storage" {
  source = "../modules/storage"
  
  name                = "st${var.environment}${var.purpose}"
  resource_group_name = module.resource_group.name
  
  containers = {
    "data" = { access_type = "private" }
    "logs" = { access_type = "private" }
  }
}
```

### 4. Compute Pattern

Create virtual machines or scale sets with appropriate configuration:

```hcl
module "compute" {
  source = "../modules/compute"
  
  name                = "vm-${var.environment}-${var.purpose}"
  resource_group_name = module.resource_group.name
  subnet_id           = module.networking.subnet_ids["app"]
  
  vm_size        = "Standard_B2s"
  admin_username = "adminuser"
  
  # Security best practice - pull from Key Vault
  admin_password = data.azurerm_key_vault_secret.vm_password.value
}
```

## Security Patterns

### 1. Key Vault Integration

Retrieve secrets from Key Vault:

```hcl
data "azurerm_key_vault" "example" {
  name                = "kv-${var.environment}"
  resource_group_name = module.resource_group.name
}

data "azurerm_key_vault_secret" "example" {
  name         = "secret-name"
  key_vault_id = data.azurerm_key_vault.example.id
}
```

### 2. Network Security Group Pattern

Secure subnets with NSGs:

```hcl
resource "azurerm_network_security_group" "example" {
  name                = "nsg-${var.subnet_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
```

## State Management Pattern

Configure backend state storage:

```hcl
tofu {
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstate12345"
    container_name       = "tfstate"
    key                  = "env.tofu.tfstate"
  }
}
```

## Error Handling & Validation

Implement proper error handling and validation:

```hcl
resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  
  lifecycle {
    prevent_destroy = true
  }
}
```

## Monitoring & Logging Pattern

Enable diagnostic settings for resources:

```hcl
resource "azurerm_monitor_diagnostic_setting" "example" {
  name                       = "diag-${var.resource_name}"
  target_resource_id         = azurerm_resource.example.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  log {
    category = "Audit"
    enabled  = true
    
    retention_policy {
      enabled = true
      days    = 90
    }
  }
  
  metric {
    category = "AllMetrics"
    enabled  = true
    
    retention_policy {
      enabled = true
      days    = 90
    }
  }
} 