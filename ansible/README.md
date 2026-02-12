# Cyber Competition Infrastructure - Ansible Deployment

This repository contains standardized Ansible roles for deploying cyber competition infrastructure across Windows and Linux systems.

## Quick Start

### 1. Prerequisites

```bash
# Install Ansible collections
ansible-galaxy collection install microsoft.ad
ansible-galaxy collection install community.windows
ansible-galaxy collection install community.docker
```

### 2. Setup Vault

```bash
cd ansible
./setup-vault.sh  # Linux/Mac
# OR
.\setup-vault.ps1  # Windows

# Edit passwords
ansible-vault edit group_vars/vault.yml
```

### 3. Configure Variables

Edit `group_vars/all.yml`:
- Competition name and team
- Domain name
- Network settings

### 4. Setup Inventory

Edit `inventory.yml` with your hosts (see `DEPLOYMENT_GUIDE.md` for examples).

### 5. Deploy

```bash
# Full deployment
ansible-playbook -i inventory.yml site.yml --ask-vault-pass

# Specific role
ansible-playbook -i inventory.yml site.yml --limit windows_dc --ask-vault-pass
```

## Standardized Roles

### Windows Roles

- **`win_dc_dns`** - Domain Controller + DNS
- **`win_ldap_kerberos`** - LDAP + Kerberos (AD DS)
- **`win_winrm`** - WinRM configuration
- **`win_smb_ftp`** - SMB file share + FTP server

### Linux Roles

- **`nix_web_stack`** - Nginx + MySQL web stack (Docker)
- **`nix_mail_server`** - Postfix + Dovecot mail server
- **`nix_monitoring`** - Grafana + rsyslog (server/client modes)

## Documentation

- **[VARIABLES.md](VARIABLES.md)** - Complete variable reference
- **[ROLES.md](ROLES.md)** - Role documentation
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Deployment instructions
- **[STANDARDIZATION_SUMMARY.md](STANDARDIZATION_SUMMARY.md)** - What was standardized
- **[MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)** - Migrating from old structure
- **[QUICK_START.md](QUICK_START.md)** - Quick reference

## Role Structure

All roles follow standard Ansible structure:

```
role_name/
├── defaults/main.yml    # Default variables
├── tasks/main.yml       # Main tasks
├── handlers/main.yml    # Handlers (if needed)
├── templates/           # Jinja2 templates
├── files/               # Static files
└── README.md           # Role documentation
```

## Key Features

✅ **Centralized Variables** - All variables in `group_vars/`  
✅ **Vault Encryption** - All passwords encrypted  
✅ **Idempotent** - Safe to run multiple times  
✅ **Standardized** - Consistent structure across all roles  
✅ **Well Documented** - Comprehensive READMEs and guides  

## Inventory Groups

Recommended groups:
- `windows_dc` - Domain Controllers
- `windows_ldap` - LDAP/Kerberos servers
- `windows_fileserver` - SMB/FTP servers
- `windows` - General Windows hosts
- `webservers` - Web stack hosts
- `mail` - Mail servers
- `monitoring_server` - Monitoring server
- `monitoring_clients` - Monitoring clients

## Testing

```bash
# Syntax check
ansible-playbook -i inventory.yml site.yml --syntax-check

# Dry run
ansible-playbook -i inventory.yml site.yml --check --ask-vault-pass

# Verbose
ansible-playbook -i inventory.yml site.yml -v --ask-vault-pass
```

## Support

See individual role READMEs for role-specific documentation and examples.
