# Quick Start Guide: Centralized Variables

## What Was Created

A centralized variable management system for uniform configuration across all services and operating systems:

### 📁 New Files

1. **`group_vars/all.yml`** - Common variables for all hosts
   - Competition settings (team, domain, org)
   - Standard users (admin, operator, service)
   - Network configuration
   - Database settings
   - Application configurations

2. **`group_vars/windows.yml`** - Windows-specific variables
   - Windows users and groups
   - Windows services
   - Windows paths
   - Scheduled tasks

3. **`group_vars/linux.yml`** - Linux-specific variables
   - Linux users and groups
   - Linux paths
   - SSL/TLS configuration
   - Docker settings
   - Postfix configuration

4. **`group_vars/vault.yml.example`** - Template for encrypted passwords
   - All sensitive passwords in one place
   - Must be encrypted with ansible-vault

5. **Documentation**
   - `VARIABLES.md` - Complete variable reference
   - `MIGRATION_GUIDE.md` - How to migrate existing playbooks
   - `README.md` - Updated main documentation
   - `QUICK_START.md` - This file

6. **Setup Scripts**
   - `setup-vault.sh` - Linux/Mac vault setup
   - `setup-vault.ps1` - Windows vault setup

## 🚀 Getting Started (3 Steps)

### Step 1: Create Vault File

```bash
cd ansible

# Linux/Mac
./setup-vault.sh

# Windows
.\setup-vault.ps1

# Or manually
cp group_vars/vault.yml.example group_vars/vault.yml
ansible-vault encrypt group_vars/vault.yml
ansible-vault edit group_vars/vault.yml  # Change all passwords!
```

### Step 2: Customize Variables

Edit `group_vars/all.yml`:
```yaml
competition_name: "CDT Charlie"
competition_team: "GreyTeam"
competition_domain: "example.com"
```

### Step 3: Use in Playbooks

Variables are automatically available! Example:

```yaml
# Before (hardcoded)
vars:
  password: "Password123!"

# After (centralized)
# No vars needed - use:
# {{ vault_service_password }}
```

## 📋 Common Variable References

### Users
```yaml
{{ standard_users.admin.username }}      # "admin"
{{ standard_users.admin.password }}      # From vault
{{ standard_users.operator.username }}   # "operator"
```

### Applications
```yaml
{{ applications.grafana.admin_user }}           # "admin"
{{ applications.grafana.admin_password }}       # From vault
{{ applications.mysql.root_password }}           # From vault
{{ applications.ldap.admin_password }}          # From vault
```

### Windows
```yaml
{{ windows_users.administrator.password }}      # From vault
{{ windows_domain.safe_mode_password }}         # From vault
{{ windows_paths.smb_share }}                   # "C:\\CDTShare"
```

### Linux
```yaml
{{ linux_users.admin.username }}                # "admin"
{{ linux_paths.web_root }}                      # "/opt/web"
{{ ssl.common_name }}                           # Domain name
```

## 🔐 Password Management

All passwords are stored in `group_vars/vault.yml` (encrypted).

**To edit passwords:**
```bash
ansible-vault edit group_vars/vault.yml
```

**To run playbooks:**
```bash
# Prompt for password
ansible-playbook playbook.yml --ask-vault-pass

# Use password file
ansible-playbook playbook.yml --vault-password-file ~/.vault_pass
```

## ✅ Benefits

1. **Uniformity**: Same users/passwords across all services
2. **Security**: All passwords encrypted in vault
3. **Maintainability**: Change once, applies everywhere
4. **Organization**: Clear structure for Windows vs Linux
5. **Documentation**: Well-documented variable structure

## 🔄 Migration Example

**Before:**
```yaml
vars:
  grafana_admin_password: "Password123!"
  mysql_root_password: "examplepassword"
  ldap_admin_password: "Password"
```

**After:**
```yaml
# Variables automatically available from group_vars/
# Use: {{ applications.grafana.admin_password }}
# Use: {{ applications.mysql.root_password }}
# Use: {{ applications.ldap.admin_password }}
```

## 📚 Next Steps

1. **Read** `VARIABLES.md` for complete variable reference
2. **Follow** `MIGRATION_GUIDE.md` to update existing playbooks
3. **Update** all playbooks to use centralized variables
4. **Test** with `--check` before deploying
5. **Rotate** passwords in vault.yml regularly

## 🆘 Need Help?

- **Variable reference**: See `VARIABLES.md`
- **Migration help**: See `MIGRATION_GUIDE.md`
- **Examples**: See updated `roles/nix_grafana/grafana.yml`

## 🎯 Key Principles

1. ✅ **All passwords** → `vault.yml` (encrypted)
2. ✅ **Common variables** → `all.yml`
3. ✅ **OS-specific** → `windows.yml` or `linux.yml`
4. ✅ **No hardcoding** → Use variables everywhere
5. ✅ **Document** → Add custom variables to docs
