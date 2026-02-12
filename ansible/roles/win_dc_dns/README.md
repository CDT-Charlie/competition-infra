# Windows Domain Controller + DNS Role

Deploys a Windows Server as an Active Directory Domain Controller with DNS services.

## Features

- Installs Active Directory Domain Services (AD DS)
- Installs DNS Server role
- Creates new AD domain
- Creates Organizational Unit (OU)
- Creates security group
- Creates domain user account
- Adds user to group

## Requirements

- Windows Server 2016 or later
- Ansible 2.9+
- `microsoft.ad` collection installed: `ansible-galaxy collection install microsoft.ad`
- Administrative access to Windows host

## Role Variables

All variables use centralized `group_vars/all.yml` by default. See `defaults/main.yml` for role-specific defaults.

### Key Variables

- `dc_hostname`: Hostname for the domain controller
- `domain_name`: FQDN of the domain (e.g., "hockey.cdtcharlie.com")
- `domain_netbios_name`: NetBIOS name for the domain
- `safe_mode_password`: Directory Services Restore Mode (DSRM) password
- `ou_name`: Organizational Unit name to create
- `group_name`: Security group name to create
- `domain_user`: Dictionary with user details (sam, given, surname, password)

## Dependencies

None

## Example Playbook

```yaml
- name: Deploy Domain Controller
  hosts: windows_dc
  roles:
    - win_dc_dns
```

## Notes

- The role handles multiple reboots automatically
- Kerberos is automatically configured as part of AD DS installation
- LDAP is automatically available through AD DS
