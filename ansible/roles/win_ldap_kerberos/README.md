# Windows LDAP + Kerberos Role

Deploys a Windows Server with Active Directory Domain Services providing LDAP and Kerberos authentication services.

## Features

- Installs Active Directory Domain Services (AD DS)
- Provides LDAP directory services (port 389, SSL 636)
- Provides Kerberos authentication (KDC service)
- Can create new domain or join existing domain
- Creates OU, group, and user (if creating new domain)

## Requirements

- Windows Server 2016 or later
- Ansible 2.9+
- `microsoft.ad` collection installed
- Administrative access to Windows host

## Role Variables

All variables use centralized `group_vars/all.yml` by default. See `defaults/main.yml` for role-specific defaults.

### Key Variables

- `dc_hostname`: Hostname for the server
- `domain_name`: FQDN of the domain
- `join_domain`: If true, joins existing domain; if false, creates new domain
- `domain_admin_user`: Username for domain join (if joining)
- `domain_admin_password`: Password for domain join
- `ldap.*`: LDAP port configuration
- `kerberos.*`: Kerberos realm configuration

## Dependencies

- `microsoft.ad` collection

## Example Playbook

```yaml
# Create new domain
- name: Deploy LDAP + Kerberos Server
  hosts: windows_ldap
  vars:
    join_domain: false
  roles:
    - win_ldap_kerberos

# Join existing domain
- name: Join Domain for LDAP + Kerberos
  hosts: windows_member
  vars:
    join_domain: true
    domain_admin_user: "administrator"
    domain_admin_password: "{{ vault_domain_admin_password }}"
  roles:
    - win_ldap_kerberos
```

## Notes

- AD DS automatically provides both LDAP and Kerberos services
- LDAP is available on port 389 (standard) and 636 (SSL)
- Kerberos KDC service runs automatically with AD DS
- Use `join_domain: true` to add as additional DC to existing domain
