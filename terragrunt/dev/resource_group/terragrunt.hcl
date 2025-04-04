# Include the root terragrunt.hcl configuration
include {
  path = find_in_parent_folders()
}

# Reference the resource_group module
terraform {
  source = "../../../modules/resource_group"
}

# Configure module-specific inputs
inputs = {
  resource_group_name = "rg-dev-example"
} 