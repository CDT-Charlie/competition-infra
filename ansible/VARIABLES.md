# Ansible Variables Documentation

This document describes the centralized variable structure for the cyber competition infrastructure deployment.

## Overview

Variables are organized into a hierarchical structure using Ansible's `group_vars` directory. This ensures consistency across all services and operating systems.

## Directory Structure

```
ansible/
├── group_vars/
│   ├── all.yml          # Variables for all hosts
│   ├── windows.yml      # Windows-specific variables
│   ├── linux.yml        # Linux-specific variables
│   └── vault.yml        # Encrypted sensitive variables (ansible-vault)
├── host_vars/           # Per-host overrides (optional)
└── inventory.yml         # Inventory file
```

## Variable Files

### `group_vars/all.yml`

Contains variables used across all hosts and services:

- **Competition Information**: Team name, domain, organization details
- **Standard Users**: Common user accounts (admin, operator, service)
- **Network Configuration**: Subnets, DNS servers
- **Domain Configuration**: LDAP/AD domain settings
- **Database Configuration**: Database credentials and settings
- **Service Accounts**: System service accounts (vmail, postfix, etc.)
- **Application Configuration**: Application-specific settings

### `group_vars/windows.yml`

Windows-specific variables:

- **Windows Users**: Administrator, Ansible user, SMB users
- **Windows Groups**: Security groups
- **Windows Services**: Service configurations
- **Windows Paths**: Standard directory paths
- **Scheduled Tasks**: Task configurations

### `group_vars/linux.yml`

Linux-specific variables:

- **Linux Users**: Standard Linux user accounts
- **Linux Groups**: Standard Linux groups
- **Linux Paths**: Standard directory paths
- **Package Management**: Package manager settings
- **SSL/TLS Configuration**: Certificate settings
- **Postfix Configuration**: Mail server settings
- **Docker Configuration**: Container settings

### `group_vars/vault.yml`

**Encrypted file** containing sensitive passwords. This file should be encrypted using `ansible-vault`.

## Creating and Managing the Vault File

### Initial Creation

```bash
# Create the vault file (will prompt for password)
ansible-vault create group_vars/vault.yml

# Copy the example file content, then encrypt it
cp group_vars/vault.yml.example group_vars/vault.yml
ansible-vault encrypt group_vars/vault.yml
```

### Editing Vault Variables

```bash
# Edit the encrypted file
ansible-vault edit group_vars/vault.yml

# View the encrypted file
ansible-vault view group_vars/vault.yml
```

### Using Vault in Playbooks

When running playbooks that use vault variables:

```bash
# Prompt for vault password
ansible-playbook playbook.yml --ask-vault-pass

# Use a password file (more secure for automation)
ansible-playbook playbook.yml --vault-password-file ~/.vault_pass

# Make password file executable and secure
chmod 600 ~/.vault_pass
```

## Variable Naming Conventions

### Standard Patterns

1. **User Variables**: `{service}_user`, `{service}_password`
2. **Password Variables**: Always prefixed with `vault_` when sensitive
3. **Service Variables**: Nested under `applications.{service_name}`
4. **OS Variables**: Prefixed with `windows_` or `linux_`

### Examples

```yaml
# Standard user
standard_users.admin.username
standard_users.admin.password  # References vault

# Application-specific
applications.grafana.admin_user
applications.grafana.admin_password  # References vault

# OS-specific
windows_users.administrator.password  # References vault
linux_users.admin.password  # References vault
```

## Using Variables in Playbooks

### Basic Usage

```yaml
- name: Create user
  user:
    name: "{{ standard_users.admin.username }}"
    password: "{{ standard_users.admin.password }}"
```

### Conditional Usage

```yaml
- name: Create Windows user
  ansible.windows.win_user:
    name: "{{ windows_users.ansible.username }}"
    password: "{{ windows_users.ansible.password }}"
  when: ansible_os_family == "Windows"
```

### Variable Precedence

Ansible variable precedence (highest to lowest):

1. `host_vars/{hostname}.yml`
2. `group_vars/{group}.yml`
3. `group_vars/all.yml`
4. Playbook `vars:` section
5. Inventory variables

## Migration Guide

To migrate existing playbooks to use centralized variables:

1. **Identify hardcoded values**: Look for passwords, usernames, domains in playbooks
2. **Replace with variable references**: Use variables from `group_vars/`
3. **Move to vault**: Move sensitive values to `vault.yml`
4. **Test**: Run playbooks with `--check` first

### Example Migration

**Before:**
```yaml
vars:
  grafana_admin_password: "Password123!"
  mysql_root_password: "examplepassword"
```

**After:**
```yaml
# Variables are now in group_vars/all.yml
# No vars section needed, or reference if overriding:
vars:
  applications:
    grafana:
      admin_password: "{{ vault_grafana_admin_password }}"
```

## Best Practices

1. **Never commit unencrypted vault files** to version control
2. **Use descriptive variable names** that indicate their purpose
3. **Group related variables** under logical namespaces
4. **Document custom variables** in playbook comments
5. **Use vault for all passwords** and sensitive data
6. **Test variable changes** before deploying to production
7. **Keep variable files organized** by function and OS

## Common Variables Reference

### Competition Settings
- `competition_name`: Competition identifier
- `competition_team`: Team name (e.g., "GreyTeam")
- `competition_domain`: Domain name (e.g., "example.com")

### Standard Users
- `standard_users.admin.*`: Admin user account
- `standard_users.operator.*`: Operator user account
- `standard_users.service.*`: Service account

### Applications
- `applications.grafana.*`: Grafana settings
- `applications.mysql.*`: MySQL settings
- `applications.ldap.*`: LDAP settings
- `applications.smb.*`: SMB share settings

### Windows Domain
- `windows_domain.domain_name`: AD domain FQDN
- `windows_domain.safe_mode_password`: DSRM password
- `windows_domain.domain_user.*`: Domain user account

## Troubleshooting

### Variable Not Found

If you get "variable not found" errors:

1. Check variable is defined in appropriate `group_vars/` file
2. Verify variable name spelling (case-sensitive)
3. Check variable precedence (host_vars override group_vars)
4. Ensure vault file is accessible if using vault variables

### Vault Password Issues

If vault decryption fails:

1. Verify vault password is correct
2. Check vault file is properly encrypted
3. Ensure `--ask-vault-pass` or `--vault-password-file` is used
4. Verify vault file path is correct

## Security Considerations

1. **Vault Encryption**: Always encrypt sensitive data
2. **Password Rotation**: Regularly rotate passwords in vault
3. **Access Control**: Limit access to vault password
4. **Audit Trail**: Track who accesses vault files
5. **Backup**: Securely backup vault files and passwords
