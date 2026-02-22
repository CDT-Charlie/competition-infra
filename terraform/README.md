# Terraform Infrastructure
## Needed files not directly in the repository:
- `app-cred-terraform-cdt-openrc.sh` - this file is important for hosting the Terraform in our OpenStack project (can get the file from the Shared Drive or in the OpenStack project from downloading it from `Identity / Application Credentials / terraform-cdt`)

## The different files in the foler and their purposes
- `providers.tf`: is used for the Terraform configuration and the passed in OpenStack provider configuration
- `networks.tf`: defines the networks and subnets resources
- `routers.tf`: defines the router and interfaces connected to the router
- `outputs.tf`: defines IDs to debug and makes it easy to confirm what Terraform created and to reuse IDs later (ports/instances)

## Initializing the environment

Source the openrc script (will prompt for your RIT password)
```
source app-cred-terraform-cdt-openrc.sh
```

can check it worked by doing any of the following, if it doesn't have the v3 its not right
```
echo $OS_AUTH_URL
```

Export this URL (substitute the Xs with the main openstack URL)
```
export OS_AUTH_URL="https://XXXXXXXXXXXXXXX:5000/v3"
```

Initialize the Terraform environment
```
terraform init
```

Apply the new changes in the `.tf` to the current environment
```
terraform apply
```

## Resource for learning more about the Terraform for the OpenStack Provider
https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/networking_address_group_v2