# Infrastructure Architecture Diagrams

## Azure Resource Architecture

```mermaid
graph TD
    subgraph "Azure Infrastructure"
        RG[Resource Groups]
        
        subgraph "Networking"
            VNET[Virtual Network]
            SNET[Subnets]
            NSG[Network Security Groups]
            RTB[Route Tables]
        end
        
        subgraph "Storage"
            ST[Storage Accounts]
            CONT[Containers]
            KV[Key Vault]
        end
        
        subgraph "Compute"
            VM[Virtual Machines]
            VMSS[VM Scale Sets]
            AKS[Kubernetes Service]
        end
        
        subgraph "Security"
            RBAC[Role-Based Access]
            PE[Private Endpoints]
            FW[Firewall]
        end
        
        subgraph "Monitoring"
            LAW[Log Analytics]
            AM[Azure Monitor]
            AI[Application Insights]
        end
    end
    
    RG --> VNET
    RG --> ST
    RG --> VM
    RG --> KV
    RG --> LAW
    
    VNET --> SNET
    SNET --> NSG
    SNET --> RTB
    
    SNET --> PE
    PE --> ST
    PE --> KV
    
    ST --> CONT
    
    SNET --> VM
    SNET --> VMSS
    SNET --> AKS
    
    VM --> LAW
    VMSS --> LAW
    AKS --> LAW
    ST --> LAW
    KV --> LAW
    
    LAW --> AM
    AM --> AI
```

## Terragrunt Structure

```mermaid
graph TD
    subgraph "Root Config"
        ROOT[terragrunt.hcl]
    end
    
    subgraph "Environments"
        DEV[Development]
        STG[Staging]
        PROD[Production]
    end
    
    subgraph "Dev Modules"
        DEV_RG[Resource Group]
        DEV_NET[Networking]
        DEV_ST[Storage]
    end
    
    subgraph "Staging Modules"
        STG_RG[Resource Group]
        STG_NET[Networking]
        STG_ST[Storage]
    end
    
    subgraph "Prod Modules"
        PROD_RG[Resource Group]
        PROD_NET[Networking]
        PROD_ST[Storage]
    end
    
    ROOT --> DEV
    ROOT --> STG
    ROOT --> PROD
    
    DEV --> DEV_RG
    DEV --> DEV_NET
    DEV --> DEV_ST
    
    STG --> STG_RG
    STG --> STG_NET
    STG --> STG_ST
    
    PROD --> PROD_RG
    PROD --> PROD_NET
    PROD --> PROD_ST
    
    DEV_NET --> |dependency| DEV_RG
    DEV_ST --> |dependency| DEV_RG
    DEV_ST --> |dependency| DEV_NET
    
    STG_NET --> |dependency| STG_RG
    STG_ST --> |dependency| STG_RG
    STG_ST --> |dependency| STG_NET
    
    PROD_NET --> |dependency| PROD_RG
    PROD_ST --> |dependency| PROD_RG
    PROD_ST --> |dependency| PROD_NET
```

## State Management

```mermaid
graph LR
    DEV[Developer Workstation] --> |tofu apply| PLAN[Execution Plan]
    CICD[CI/CD Pipeline] --> |tofu apply| PLAN
    
    PLAN --> LOCK[State Lock]
    LOCK --> STATE[Azure Storage<br/>OpenTofu State]
    STATE --> |Read Current State| PLAN
    
    STATE --> AZURE[Azure Resources]
    PLAN --> |Create/Update/Delete| AZURE
```

## Terragrunt & Terratest Workflow

```mermaid
graph TD
    subgraph "Development Process"
        CODE[Code Changes] --> PR[Pull Request]
        PR --> CI[CI Pipeline]
        CI --> LINT[Linting & Validation]
        LINT --> TEST[Terratest]
        TEST --> REVIEW[Plan Review]
        REVIEW --> APPLY[Apply Changes]
    end
    
    subgraph "Testing"
        TEST --> |Create| TEST_RG[Temporary<br/>Resource Group]
        TEST --> |Deploy| TEST_INFRA[Test Infrastructure]
        TEST --> |Validate| TEST_ASSERT[Assertions]
        TEST --> |Cleanup| TEST_DESTROY[Destroy Resources]
    end
    
    subgraph "Deployment"
        APPLY --> |dev| DEV_ENV[Dev Environment]
        APPLY --> |staging| STG_ENV[Staging Environment]
        APPLY --> |production| PROD_ENV[Production Environment]
    end
    
    DEV_ENV --> |Promote| STG_ENV
    STG_ENV --> |Promote| PROD_ENV
```

## Multi-Environment Setup

```mermaid
graph TB
    subgraph "Development"
        DEV_STATE[Dev State]
        DEV_RG[Resource Group]
        DEV_RESOURCES[Resources]
    end
    
    subgraph "Staging"
        STG_STATE[Staging State]
        STG_RG[Resource Group]
        STG_RESOURCES[Resources]
    end
    
    subgraph "Production"
        PROD_STATE[Production State]
        PROD_RG[Resource Group]
        PROD_RESOURCES[Resources]
    end
    
    CODE[Code Repository] --> DEV_STATE
    CODE --> STG_STATE
    CODE --> PROD_STATE
    
    DEV_STATE --> DEV_RG
    DEV_RG --> DEV_RESOURCES
    
    STG_STATE --> STG_RG
    STG_RG --> STG_RESOURCES
    
    PROD_STATE --> PROD_RG
    PROD_RG --> PROD_RESOURCES
```

## Network Security Model

```mermaid
graph TB
    INTERNET[Internet] --> |Port 443| FW[Azure Firewall]
    
    FW --> |Filtered Traffic| PL[Public Subnet]
    PL --> |App Gateway| APP[App Subnet]
    APP --> |Service Endpoints| DAT[Data Subnet]
    
    subgraph "VNet"
        PL
        APP
        DAT
    end
    
    APP --> VM[VM Scale Set]
    DAT --> DB[Azure SQL]
    DAT --> ST[Storage Account]
```
