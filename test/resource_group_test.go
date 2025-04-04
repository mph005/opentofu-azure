package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestResourceGroup(t *testing.T) {
	t.Parallel()

	// Generate a random name to prevent a naming conflict
	uniqueID := random.UniqueId()
	rgName := "rg-test-" + uniqueID

	// Terragrunt working directory
	workingDir := "../terragrunt/dev/resource_group"

	terraformOptions := &terraform.Options{
		// Point to the terragrunt directory
		TerraformDir: workingDir,
		// Use Terragrunt instead of Terraform
		TerraformBinary: "terragrunt",
		// Variables to pass to our Terragrunt/Terraform
		Vars: map[string]interface{}{
			"resource_group_name": rgName,
		},
	}

	// At the end of the test, run `terragrunt destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// Run `terragrunt apply` to create the resources
	terraform.InitAndApply(t, terraformOptions)

	// Check if resource group exists
	exists := azure.ResourceGroupExists(t, rgName, "")
	assert.True(t, exists, "Resource group should exist")

	// Get the outputs of the terragrunt configuration
	output := terraform.OutputAll(t, terraformOptions)

	// Verify the outputs
	assert.Equal(t, rgName, output["name"])
	assert.NotEmpty(t, output["id"], "Resource group ID should not be empty")
	assert.Equal(t, "East US", output["location"], "Resource group location should match")
}
