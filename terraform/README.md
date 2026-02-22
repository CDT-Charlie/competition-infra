# Terraform Infrastructure
## Needed files not directly in the repository:
- `cdtcharlie-openrc.sh` - this file is important for hosting the Terraform in our OpenStack project (can get the file from the Shared Drive or in the OpenStack project from downloading it from `Project / API Access`)

## The different files in the foler and their purposes
`config.tf`: is used for the Terraform configuration and the passed in OpenStack provider configuration

## Initializing the environment

Source the openrc script
```
source cdtcharlie-openrc.sh
```

Initialize the Terraform environment
```
terraform init
```

Apply the new changes in the `.tf` to the current environment
```
terraform apply
```
