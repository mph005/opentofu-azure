package test

import (
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestStorage(t *testing.T) {
	t.Parallel()

	// Generate a random suffix to prevent naming conflicts
	uniqueID := strings.ToLower(random.UniqueId())
	rgName := "rg-test-" + uniqueID
	saName := "sttest" + uniqueID // Storage account names must be lowercase alphanumeric

	// Make sure storage account name is not too long (24 chars max)
	if len(saName) > 24 {
		saName = saName[:24]
	}

	// Terraform working directory for resource group (need to create this first)
	rgWorkingDir := "../terragrunt/dev/resource_group"

	// Terraform options for resource group
	rgTerraformOptions := &terraform.Options{
		TerraformDir:    rgWorkingDir,
		TerraformBinary: "terragrunt",
		Vars: map[string]interface{}{
			"resource_group_name": rgName,
		},
	}

	// Create resource group first and defer deletion
	defer terraform.Destroy(t, rgTerraformOptions)
	terraform.InitAndApply(t, rgTerraformOptions)

	// Terraform working directory for storage
	storageWorkingDir := "../terragrunt/dev/storage"

	// Terraform options for storage
	storageTerraformOptions := &terraform.Options{
		TerraformDir:    storageWorkingDir,
		TerraformBinary: "terragrunt",
		Vars: map[string]interface{}{
			"name":                saName,
			"resource_group_name": rgName,
			"containers": map[string]interface{}{
				"test-container": map[string]interface{}{
					"access_type": "private",
				},
			},
			"enable_versioning":                    true,
			"blob_soft_delete_retention_days":      7,
			"container_soft_delete_retention_days": 7,
			// Skip network rules for the test to make it simpler
			"network_rules": map[string]interface{}{
				"default_action":             "Allow",
				"ip_rules":                   []string{},
				"virtual_network_subnet_ids": []string{},
			},
		},
	}

	// Clean up storage resources when test finishes
	defer terraform.Destroy(t, storageTerraformOptions)

	// Deploy the storage configuration
	terraform.InitAndApply(t, storageTerraformOptions)

	// Get storage account details
	saID := terraform.Output(t, storageTerraformOptions, "id")
	assert.NotEmpty(t, saID, "Storage account ID should not be empty")

	// Verify storage account exists
	exists := azure.StorageAccountExists(t, saName, rgName, "")
	assert.True(t, exists, "Storage account should exist")

	// Get container details
	containerURLs := terraform.OutputMap(t, storageTerraformOptions, "container_urls")
	assert.Contains(t, containerURLs, "test-container", "Container should be created")

	// More assertions can be added to verify storage account configuration
	// For example, verify the storage account tier, replication type, etc.
}
