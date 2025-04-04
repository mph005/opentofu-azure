package test

import (
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestNetworking(t *testing.T) {
	t.Parallel()

	// Generate a random suffix to prevent naming conflicts
	uniqueID := strings.ToLower(random.UniqueId())
	rgName := "rg-test-" + uniqueID
	vnetName := "vnet-test-" + uniqueID

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

	// Terraform working directory for networking
	networkingWorkingDir := "../terragrunt/dev/networking"

	// Terraform options for networking
	networkingTerraformOptions := &terraform.Options{
		TerraformDir:    networkingWorkingDir,
		TerraformBinary: "terragrunt",
		Vars: map[string]interface{}{
			"name":                vnetName,
			"resource_group_name": rgName,
			"address_space":       []string{"10.10.0.0/16"},
			"subnets": map[string]interface{}{
				"test-subnet": map[string]interface{}{
					"address_prefix": "10.10.1.0/24",
				},
			},
			"create_network_security_group": true,
			"subnet_nsg_associations": map[string]interface{}{
				"test-subnet": "test-subnet",
			},
		},
	}

	// Clean up networking resources when test finishes
	defer terraform.Destroy(t, networkingTerraformOptions)

	// Deploy the networking configuration
	terraform.InitAndApply(t, networkingTerraformOptions)

	// Get VNet details
	vnetID := terraform.Output(t, networkingTerraformOptions, "vnet_id")
	assert.NotEmpty(t, vnetID, "VNet ID should not be empty")

	// Get subnet details
	subnetIDs := terraform.OutputMap(t, networkingTerraformOptions, "subnet_ids")
	assert.Contains(t, subnetIDs, "test-subnet", "Subnet should be created")

	// Verify NSG association
	nsgID := terraform.Output(t, networkingTerraformOptions, "network_security_group_id")
	assert.NotEmpty(t, nsgID, "NSG ID should not be empty")

	// Added Azure verification
	exists := azure.VirtualNetworkExists(t, vnetName, rgName, "")
	assert.True(t, exists, "Virtual network should exist in Azure")
}
