# Terratest Integration for OpenTofu Azure Project

This directory contains Terratest tests for our OpenTofu/Azure infrastructure code.

## Prerequisites

1. **Go 1.20 or later**
2. **OpenTofu or Terraform CLI**
3. **Terragrunt CLI**
4. **Azure CLI** (authenticated with appropriate permissions)

## Test Setup

The tests are written using [Terratest](https://terratest.gruntwork.io/), a Go library that makes it easier to test infrastructure code. The tests use actual Azure resources, so make sure you're running the tests using an Azure account with appropriate permissions and resources.

## Running Tests

1. **Set Up Azure Authentication**

   Login to Azure CLI:

   ```bash
   az login
   ```

   Set the subscription:

   ```bash
   az account set --subscription <your-subscription-id>
   ```

2. **Download Dependencies**

   ```bash
   go mod download
   ```

3. **Run All Tests**

   ```bash
   go test -v ./...
   ```

   or run individual tests:

   ```bash
   go test -v -run TestResourceGroup
   go test -v -run TestNetworking
   go test -v -run TestStorage
   ```

## Test Structure

Each test file (`*_test.go`) contains tests for a specific module:

- `resource_group_test.go`: Tests for the resource group module
- `networking_test.go`: Tests for the networking module
- `storage_test.go`: Tests for the storage module

The tests follow this pattern:

1. Create random names for resources to prevent conflicts
2. Create Terragrunt options with appropriate variables
3. Run `terragrunt apply` to create the resources
4. Validate that the resources were created correctly and have the expected properties
5. Run `terragrunt destroy` to clean up resources when the test is finished

## Best Practices

1. **Always clean up resources**: Use `defer terraform.Destroy()` to ensure resources are cleaned up even if tests fail.
2. **Use random names**: Generate random, unique names for all resources to prevent naming conflicts when running tests in parallel.
3. **Run tests in parallel**: Use `t.Parallel()` to run tests in parallel, but be aware of Azure limits and quotas.
4. **Test actual behavior**: Verify that resources are created correctly by checking their properties in Azure.

## Troubleshooting

If tests fail, check:

1. **Azure Permissions**: Ensure you have sufficient permissions to create and delete resources in Azure.
2. **Resource Quota Limits**: Ensure your Azure subscription has sufficient quota to create the resources required by the tests.
3. **Clean up manual resources**: If tests fail before cleanup, manually delete any resources that were created to avoid unnecessary charges.

## Adding New Tests

To add tests for a new module:

1. Create a new test file (e.g., `new_module_test.go`)
2. Import the required testing packages
3. Define a test function that creates the necessary resources
4. Validate that the resources were created correctly
5. Ensure all resources are cleaned up when the test is finished 