# Azure Infrastructure Architecture

This document outlines the architecture of our Azure infrastructure deployment using OpenTofu with Terragrunt and Terratest.

## Architecture Overview

Our infrastructure follows a layered approach with clear separation of concerns:

```ascii
┌────────────────────────────────────────────────────────────────┐
│                     Azure Infrastructure                        │
├────────────┬────────────┬────────────┬────────────┬────────────┤
│  Resource  │            │            │            │            │
│   Groups   │ Networking │  Storage   │  Compute   │  Security  │
└────────────┴────────────┴────────────┴────────────┴────────────┘
```

## Component Relationships

### Resource Dependencies

Resources follow this dependency hierarchy:

1. Resource Group (Foundation)
2. Networking (Virtual Networks, Subnets, NSGs)
3. Storage and Key Vault (Secured Services)
4. Compute Resources (VMs, App Services, etc.)
5. Monitoring and Diagnostics

These dependencies are explicitly managed through Terragrunt's dependency blocks, ensuring proper deployment order.

### Data Flow

Data flows through our infrastructure as follows:

1. **External Traffic**: Enters through Azure Front Door / Application Gateway
2. **Application Layer**: Processed in App Service / VM Scale Sets
3. **Data Storage**: Persisted in Azure Storage / Databases
4. **Monitoring**: All components send logs to Azure Monitor

## Infrastructure Patterns

### Multi-Environment Setup

We use separate state files and configurations for each environment, managed by Terragrunt:

- **Development**: For feature testing (lowest cost, less redundancy)
- **Staging**: Production-like environment for pre-deployment validation
- **Production**: Highly available, redundant configuration

Terragrunt enables us to maintain DRY configurations across environments while ensuring proper isolation.

### Network Segmentation

Our network is segmented for security:

- **App Subnets**: For application components
- **Data Subnets**: For databases and storage services
- **Management Subnets**: For administrative access

### State Management

OpenTofu state is stored remotely in Azure Storage with locking to prevent concurrent modifications:

```ascii
┌────────────────────┐     ┌────────────────────┐
│  OpenTofu Clients  │────▶│  Azure Storage     │
│  (CI/CD Pipeline)  │◀────│  (State Backend)   │
└────────────────────┘     └────────────────────┘
```

Terragrunt automates the state configuration for each environment and module:

```ascii
┌─────────────┐     ┌────────────────┐     ┌─────────────────┐
│  Terragrunt │────▶│  OpenTofu      │────▶│  Azure Storage  │
│  Config     │     │  State Backend │     │  (State Files)  │
└─────────────┘     └────────────────┘     └─────────────────┘
```

## Module Boundaries

### Resource Group Module

- **Purpose**: Create and manage resource groups
- **Inputs**: Name, location, tags
- **Outputs**: Resource group name, ID, location

### Networking Module

- **Purpose**: Create Virtual Networks, Subnets, NSGs
- **Inputs**: VNET address space, subnet configurations
- **Outputs**: VNET ID, subnet IDs, NSG IDs

### Storage Module

- **Purpose**: Create and configure storage accounts and containers
- **Inputs**: Storage account name, container configurations
- **Outputs**: Storage account IDs, connection strings, keys

### Compute Module

- **Purpose**: Deploy and configure VMs and VM Scale Sets
- **Inputs**: VM size, OS image, subnet ID
- **Outputs**: VM IDs, IP addresses

## Terragrunt Structure

Our Terragrunt configuration follows this structure:

```text
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

This structure enables us to:

- Share common configuration across environments
- Define environment-specific variables
- Manage dependencies between resources
- Apply changes to individual modules or entire environments

## Testing Architecture

We use Terratest to validate our infrastructure code through automated tests:

```ascii
┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│  Terratest     │────▶│  Terragrunt    │────▶│  Real Azure    │
│  Go Tests      │     │  + OpenTofu    │     │  Resources     │
└────────────────┘     └────────────────┘     └────────────────┘
       │                                             │
       │                                             │
       └─────────────────┐               ┌───────────┘
                         ▼               ▼
                    ┌────────────────────────────┐
                    │  Validation & Cleanup      │
                    └────────────────────────────┘
```

Test files are organized by module and validate both the provisioning and configuration of resources.

## System Interfaces

### Azure CLI / Azure SDK

- Used for initial authentication and state backend setup

### OpenTofu Provider

- Interfaces with Azure API for resource provisioning

### Monitoring Interfaces

- Azure Monitor
- Log Analytics
- Application Insights

## Deployment Architecture

Our deployment follows a GitOps approach with Terragrunt and CI/CD:

```ascii
┌─────────────┐    ┌──────────────┐    ┌─────────────────┐
│  Git Repo   │───▶│ CI/CD System │───▶│ Terratest Tests │
└─────────────┘    └──────────────┘    └─────────────────┘
                         │                      │
                         ▼                      │
                   ┌──────────────┐             │
                   │ Plan Review  │             │
                   └──────────────┘             │
                         │                      │
                         ▼                      │
               ┌──────────────────────┐         │
               │ Terragrunt Apply     │◀────────┘
               └──────────────────────┘
                         │
                         ▼
               ┌──────────────────────┐
               │ Azure Resources      │
               └──────────────────────┘
```

## Disaster Recovery

- Backups stored in geo-redundant storage
- Cross-region recovery plans for critical services
- Regular disaster recovery testing
- Infrastructure defined as code for rapid recovery
