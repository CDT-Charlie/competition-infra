# Ansible Infrastructure Deployment

This directory contains Ansible playbooks and roles for deploying cyber competition infrastructure across Windows and Linux systems.

## Structure

```
ansible/
├── site.yml                    # Main playbook - deploys all services
├── group_vars/                 # Centralized variables
│   ├── all.yml                # Common variables for all hosts
│   ├── windows.yml            # Windows-specific variables
│   └── linux.yml              # Linux-specific variables
└── roles/                      # Ansible roles
    ├── win_base/              # Base Windows setup
    ├── win_dc_dns/            # Windows Domain Controller + DNS
    ├── win_ldap_kerberos/     # Windows LDAP + Kerberos (AD DS)
    ├── win_winrm/             # Windows WinRM configuration
    ├── win_smb_ftp/           # Windows SMB file share + FTP server
    ├── nix_base/              # Base Linux setup
    ├── nix_web_stack/         # Nginx + MySQL web stack (Docker)
    ├── nix_mail_server/       # Postfix + Dovecot mail server
    └── nix_monitoring/        # Grafana + rsyslog monitoring
```

## Role Structure

All roles follow a simplified structure with only two directories:

```
role_name/
├── tasks/
│   └── main.yml      # All tasks for the role
└── files/            # Static files (if needed)
```

**No templates, defaults, or handlers folders** - keeping the structure simple and uniform.

## Quick Start

### Prerequisites

1. **Install Ansible** (2.9+)
   ```bash
   pip install ansible
   ```

2. **Install Required Collections**
   ```bash
   ansible-galaxy collection install microsoft.ad
   ansible-galaxy collection install community.windows
   ansible-galaxy collection install community.docker
   ```

3. **Configure Inventory**
   Create or edit `inventory.yml` with your target hosts:
   ```yaml
   all:
     children:
       windows_dc:
         hosts:
           dc1:
             ansible_host: 10.0.100.10
       windows_fileserver:
         hosts:
           fileserver1:
             ansible_host: 10.0.100.12
       webservers:
         hosts:
           web1:
             ansible_host: 10.0.100.20
       # ... etc
   ```

### Deploy All Services

```bash
ansible-playbook -i inventory.yml site.yml
```

### Deploy Specific Service

```bash
# Windows Domain Controller
ansible-playbook -i inventory.yml site.yml --limit windows_dc

# Linux Web Stack
ansible-playbook -i inventory.yml site.yml --limit webservers

# Linux Mail Server
ansible-playbook -i inventory.yml site.yml --limit mail
```

## Roles Overview

### Windows Roles

#### `win_base`
**Purpose:** Common Windows system setup  
**Tasks:**
- Ensures WinRM service is enabled
- Enables File and Printer Sharing firewall rules

**Usage:** Included automatically by other Windows roles

#### `win_dc_dns`
**Purpose:** Deploy Windows Domain Controller with DNS  
**Deploys:**
- Active Directory Domain Services (AD DS)
- DNS Server
- Creates new domain
- Creates OU, security group, and domain user

**Variables:** See `group_vars/windows.yml` → `windows_dc`

**Inventory Group:** `windows_dc`

#### `win_ldap_kerberos`
**Purpose:** Deploy Windows server with LDAP + Kerberos (AD DS)  
**Deploys:**
- Active Directory Domain Services
- LDAP directory services (port 389, SSL 636)
- Kerberos authentication (KDC service)

**Variables:** See `group_vars/windows.yml` → `windows_dc`

**Inventory Group:** `windows_ldap`

#### `win_winrm`
**Purpose:** Configure WinRM and Ansible management environment  
**Deploys:**
- WinRM service configuration
- Ansible user account
- Login banner
- Service monitoring

**Variables:** See `group_vars/windows.yml` → `windows_winrm`

**Inventory Group:** `windows`

#### `win_smb_ftp`
**Purpose:** Deploy SMB file share and FTP server  
**Deploys:**
- SMB file share with NTFS permissions
- FTP server (IIS-based)
- User/group management
- Firewall rules
- Optional persistence mechanism

**Variables:** See `group_vars/windows.yml` → `windows_smb_ftp`

**Inventory Group:** `windows_fileserver`

### Linux Roles

#### `nix_base`
**Purpose:** Common Linux system setup  
**Tasks:**
- Updates apt cache
- Installs common packages (curl, wget, gnupg, etc.)

**Usage:** Included automatically by other Linux roles

#### `nix_web_stack`
**Purpose:** Deploy Nginx + MySQL web stack using Docker  
**Deploys:**
- Docker
- MySQL container
- PHP container (with MySQL support)
- Nginx container
- Database initialization

**Variables:** See `group_vars/linux.yml` → `web_stack`

**Inventory Group:** `webservers`

**Files:**
- `files/nginx.conf` - Nginx configuration
- `files/Dockerfile.php` - PHP Dockerfile
- `files/index.php` - Web application
- `files/init.sql` - Database initialization script

#### `nix_mail_server`
**Purpose:** Deploy Postfix + Dovecot mail server  
**Deploys:**
- Postfix (SMTP server)
- Dovecot (IMAP/POP3 server)
- SSL/TLS certificates
- Service accounts (vmail)

**Variables:** See `group_vars/linux.yml` → `mail_server`

**Inventory Group:** `mail`

**Files:**
- `files/dovecot.conf` - Dovecot configuration

#### `nix_monitoring`
**Purpose:** Deploy Grafana monitoring and rsyslog logging  
**Deploys:**
- Grafana dashboard
- rsyslog (server or client mode)
- Log rotation (server mode)

**Variables:** See `group_vars/linux.yml` → `grafana` and `rsyslog`

**Inventory Groups:**
- `monitoring_server` - Server mode (receives logs)
- `monitoring_clients` - Client mode (forwards logs)

**Configuration:**
- Set `rsyslog_mode: "server"` for server mode
- Set `rsyslog_mode: "client"` for client mode

## Variable Management

### Variable Files

Variables are organized in `group_vars/`:

- **`all.yml`** - Common variables for all hosts
- **`windows.yml`** - Windows-specific variables
- **`linux.yml`** - Linux-specific variables

### Variable Structure

Variables are organized hierarchically:

```yaml
# Windows example
windows_dc:
  domain_name: "hockey.cdtcharlie.com"
  netbios_name: "HOCKEY1"
  safe_mode_password: "Password123!"
  # ...

# Linux example
grafana:
  http_port: 3000
  domain: "CharlieGreyTeam"
  admin_password: "Password123!"
  # ...
```

### Using Variables in Playbooks

Variables are referenced in `site.yml` playbook `vars:` sections:

```yaml
vars:
  domain_name: "{{ windows_dc.domain_name }}"
  admin_password: "{{ grafana.admin_password }}"
```

## Inventory Groups

Recommended inventory groups:

### Windows
- `windows_dc` - Domain Controllers
- `windows_ldap` - LDAP/Kerberos servers
- `windows_fileserver` - SMB/FTP servers
- `windows` - General Windows hosts (WinRM)

### Linux
- `webservers` - Web stack hosts
- `mail` - Mail servers
- `monitoring_server` - Monitoring server (rsyslog server mode)
- `monitoring_clients` - Monitoring clients (rsyslog client mode)

## Testing

### Syntax Check
```bash
ansible-playbook -i inventory.yml site.yml --syntax-check
```

### Dry Run
```bash
ansible-playbook -i inventory.yml site.yml --check
```

### Verbose Output
```bash
ansible-playbook -i inventory.yml site.yml -v
```

### Test Specific Role
```bash
ansible-playbook -i inventory.yml site.yml --limit windows_dc --check
```

## Design Principles

1. **Simple Structure** - Only `tasks/` and `files/` folders
2. **No Templates** - Use `copy` with `content:` for variable substitution
3. **Centralized Variables** - All variables in `group_vars/`
4. **Idempotent** - Safe to run multiple times
5. **Base Roles** - Common setup tasks in `win_base` and `nix_base`

## File Handling

### Static Files
Static files (nginx.conf, dovecot.conf, etc.) are kept in `files/` directory and copied as-is.

### Files with Variables
For files that need variable substitution (like postfix.conf), use `copy` with `content:`:

```yaml
- name: Deploy config with variables
  copy:
    dest: /etc/service/config.conf
    content: |
      hostname = {{ hostname }}
      domain = {{ domain }}
```

## Common Tasks

### Update Variables
Edit the appropriate `group_vars/*.yml` file:
```bash
# Edit Windows variables
vim group_vars/windows.yml

# Edit Linux variables
vim group_vars/linux.yml
```

### Add New Role
1. Create `roles/new_role/tasks/main.yml`
2. Add `files/` directory if needed
3. Add role to `site.yml`
4. Add variables to appropriate `group_vars/` file

### Debug Issues
```bash
# Verbose output
ansible-playbook -i inventory.yml site.yml -vvv

# Test on single host
ansible-playbook -i inventory.yml site.yml --limit hostname

# Check what would change
ansible-playbook -i inventory.yml site.yml --check --diff
```

## Documentation

- **`RESTRUCTURE_COMPLETE.md`** - Details of the restructure implementation
- **`RESTRUCTURE_PLAN_SIMPLE.md`** - Original restructure plan
- **`RESTRUCTURE_SIMPLE_REF.md`** - Quick reference for restructure

## Notes

- All passwords are currently in plain text in `group_vars/` files
- Consider implementing Ansible Vault for production use
- Old role directories may still exist for reference (can be removed after verification)
- Some roles may have old playbook files alongside new role structure (for reference)

## Support

For role-specific documentation, see individual role directories. Each role should have a `README.md` with detailed information.
