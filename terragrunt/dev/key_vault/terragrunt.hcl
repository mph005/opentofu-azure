include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/key_vault"
}

# Dependency on resource group module
dependency "resource_group" {
  config_path = "../resource_group"
}

# Dependency on networking module for private endpoint subnet
dependency "networking" {
  config_path = "../networking"
  skip_outputs = false
}

locals {
  # Extract environment specific variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  subscription_id  = local.environment_vars.locals.subscription_id
  tenant_id        = local.environment_vars.locals.tenant_id
}

inputs = {
  key_vault_name              = "kv-dev-shared-${substr(md5(local.subscription_id), 0, 8)}"
  resource_group_name         = dependency.resource_group.outputs.name
  location                     = dependency.resource_group.outputs.location
  tenant_id                   = local.tenant_id
  sku_name                    = "standard"
  enabled_for_disk_encryption = true
  soft_delete_retention_days  = 90
  purge_protection_enabled    = true
  enable_rbac_authorization   = false

  # Network rules to restrict access  
  network_acls = {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = []
    virtual_network_subnet_ids = [dependency.networking.outputs.subnet_ids["data"]]
  }
  
  # Access policies (only used if RBAC is disabled)
  access_policies = {
    # Example policy for a service principal or managed identity
    "app" = {
      object_id               = "00000000-0000-0000-0000-000000000000" # Replace with actual object ID
      secret_permissions      = ["Get", "List"]
      key_permissions         = ["Get", "List"]
      certificate_permissions = ["Get", "List"]
      storage_permissions     = []
    }
  }
  
  # Create a private endpoint for the Key Vault
  private_endpoint_subnet_id = dependency.networking.outputs.subnet_ids["data"]
  
  # Uncomment if you have a private DNS zone
  # private_dns_zone_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
  
  # Example secrets (for demonstration only - don't store sensitive values in the file)
  secrets = {
    "example-secret" = {
      value        = "SecureValue123!" # In production, use external secret store or pass this at runtime
      content_type = "text/plain"
      tags         = { "environment" = "dev" }
    }
  }
  
  tags = {
    Environment = "dev"
    ManagedBy   = "Terragrunt"
    Service     = "Security"
  }
} 