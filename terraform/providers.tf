terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53.0"
    }
  }
}

# this is required since Terraform needs a provider block, in our case it is passed in as a secret through sourcing a file
provider "openstack" {
  auth_url  = "https://openstack.cyberrange.rit.edu:5000/v3"
  region    = "CyberRange"
  tenant_id = "12416c28c79d4f05bad1df073be63aaa"
}  