package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestKeyVaultModule(t *testing.T) {
	t.Parallel()

	// Generate a random name to prevent a naming conflict
	uniqueID := random.UniqueId()
	keyVaultName := fmt.Sprintf("kvtest%s", uniqueID)
	rgName := fmt.Sprintf("rg-test-%s", uniqueID)
	vnetName := fmt.Sprintf("vnet-test-%s", uniqueID)
	location := "eastus"

	// Create resource group first
	rgWorkingDir := "../modules/resource_group"
	rgTerraformOptions := &terraform.Options{
		TerraformDir: rgWorkingDir,
		Vars: map[string]interface{}{
			"resource_group_name": rgName,
			"location":            location,
			"tags": map[string]string{
				"Environment": "Test",
				"ManagedBy":   "Terratest",
			},
		},
	}

	// Clean up resources when the test is completed
	defer terraform.Destroy(t, rgTerraformOptions)
	terraform.InitAndApply(t, rgTerraformOptions)

	// Create VNet and subnet for private endpoint
	networkingWorkingDir := "../modules/networking"
	networkingTerraformOptions := &terraform.Options{
		TerraformDir: networkingWorkingDir,
		Vars: map[string]interface{}{
			"name":                vnetName,
			"resource_group_name": rgName,
			"location":            location,
			"address_space":       []string{"10.0.0.0/16"},
			"subnets": map[string]interface{}{
				"default": map[string]interface{}{
					"address_prefix": "10.0.1.0/24",
				},
				"data": map[string]interface{}{
					"address_prefix": "10.0.2.0/24",
				},
			},
			"tags": map[string]string{
				"Environment": "Test",
				"ManagedBy":   "Terratest",
			},
		},
	}

	// Clean up VNet resources
	defer terraform.Destroy(t, networkingTerraformOptions)
	terraform.InitAndApply(t, networkingTerraformOptions)

	// Get subnet IDs output
	subnetIDs := terraform.OutputMap(t, networkingTerraformOptions, "subnet_ids")
	dataSubnetID := subnetIDs["data"]

	// Create Key Vault
	keyVaultWorkingDir := "../modules/key_vault"
	keyVaultTerraformOptions := &terraform.Options{
		TerraformDir: keyVaultWorkingDir,
		Vars: map[string]interface{}{
			"key_vault_name":              keyVaultName,
			"resource_group_name":         rgName,
			"location":                    location,
			"tenant_id":                   azure.GetTenantID(t),
			"sku_name":                    "standard",
			"enabled_for_disk_encryption": true,
			"soft_delete_retention_days":  7,
			"purge_protection_enabled":    false, // Set to false for testing to allow cleanup
			"enable_rbac_authorization":   false,
			"network_acls": map[string]interface{}{
				"bypass":                     "AzureServices",
				"default_action":             "Allow", // Set to allow for testing
				"ip_rules":                   []string{},
				"virtual_network_subnet_ids": []string{},
			},
			"private_endpoint_subnet_id": dataSubnetID,
			"secrets": map[string]interface{}{
				"test-secret": map[string]interface{}{
					"value":        "SecureTestValue",
					"content_type": "text/plain",
					"tags":         map[string]string{"environment": "test"},
				},
			},
			"tags": map[string]string{
				"Environment": "Test",
				"ManagedBy":   "Terratest",
			},
		},
	}

	// Clean up Key Vault resources
	defer terraform.Destroy(t, keyVaultTerraformOptions)
	terraform.InitAndApply(t, keyVaultTerraformOptions)

	// Get Key Vault outputs
	keyVaultID := terraform.Output(t, keyVaultTerraformOptions, "id")
	keyVaultURI := terraform.Output(t, keyVaultTerraformOptions, "uri")

	// Verify Key Vault exists in Azure
	exists := azure.KeyVaultExists(t, keyVaultName, rgName, "")
	assert.True(t, exists, "Key Vault should exist")

	// Assertions to validate Key Vault outputs
	assert.NotEmpty(t, keyVaultID, "Key Vault ID should not be empty")
	assert.NotEmpty(t, keyVaultURI, "Key Vault URI should not be empty")

	// Verify the secret was created (just checking the structure, not the actual value)
	secretIDs := terraform.OutputMap(t, keyVaultTerraformOptions, "secret_ids")
	assert.Contains(t, secretIDs, "test-secret", "The test secret should be created")
}
