# Competition Infrastructure

RIT Cyber Defense Techniques Group Charlie Grey Team infrastructure deployment repository.

## Overview

This repository contains Ansible automation for deploying cyber competition infrastructure across Windows and Linux systems. The infrastructure includes domain controllers, web servers, mail servers, monitoring systems, and file sharing services.

## Repository Structure

```
competition-infra/
├── ansible/              # Ansible playbooks and roles
│   ├── site.yml         # Main deployment playbook
│   ├── group_vars/      # Centralized variables
│   └── roles/           # Ansible roles
│       ├── win_*        # Windows roles
│       └── nix_*        # Linux roles
└── README.md            # This file
```

## Quick Start

### Prerequisites

- Ansible 2.9 or later
- Python 3.6+
- Access to target Windows and Linux hosts
- Required Ansible collections (see [ansible/README.md](ansible/README.md))

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd competition-infra
   ```

2. **Install Ansible collections**
   ```bash
   cd ansible
   ansible-galaxy collection install microsoft.ad
   ansible-galaxy collection install community.windows
   ansible-galaxy collection install community.docker
   ```

3. **Configure inventory**
   Edit `ansible/inventory.yml` with your target hosts

4. **Configure variables**
   Edit `ansible/group_vars/windows.yml` and `ansible/group_vars/linux.yml` as needed

5. **Deploy**
   ```bash
   cd ansible
   ansible-playbook -i inventory.yml site.yml
   ```

## What Gets Deployed

### Windows Services

- **Domain Controller + DNS** (`win_dc_dns`)
  - Active Directory Domain Services
  - DNS Server
  - Domain creation and user management

- **LDAP + Kerberos** (`win_ldap_kerberos`)
  - Active Directory DS with LDAP and Kerberos services

- **WinRM** (`win_winrm`)
  - WinRM service configuration
  - Ansible management user
  - System banners

- **SMB + FTP** (`win_smb_ftp`)
  - SMB file shares
  - FTP server with persistence

### Linux Services

- **Web Stack** (`nix_web_stack`)
  - Nginx web server
  - MySQL database
  - PHP application server
  - All containerized with Docker

- **Mail Server** (`nix_mail_server`)
  - Postfix (SMTP)
  - Dovecot (IMAP/POP3)
  - SSL/TLS certificates

- **Monitoring** (`nix_monitoring`)
  - Grafana dashboards
  - rsyslog centralized logging
  - Log rotation and filtering

## Documentation

- **[ansible/README.md](ansible/README.md)** - Complete Ansible documentation
  - Role descriptions
  - Variable reference
  - Usage examples
  - Troubleshooting

## Architecture

### Design Principles

- **Simple Structure** - Only `tasks/` and `files/` folders in roles
- **Centralized Variables** - All variables in `group_vars/`
- **Uniform** - Consistent structure across all roles
- **Base Roles** - Common setup tasks separated

### Role Structure

All roles follow a simplified structure:

```
role_name/
├── tasks/
│   └── main.yml      # All tasks
└── files/            # Static files (if needed)
```

## Inventory Groups

The deployment uses the following inventory groups:

- `windows_dc` - Domain Controllers
- `windows_ldap` - LDAP/Kerberos servers
- `windows_fileserver` - SMB/FTP servers
- `windows` - General Windows hosts
- `webservers` - Web stack hosts
- `mail` - Mail servers
- `monitoring_server` - Monitoring server
- `monitoring_clients` - Monitoring clients

## Variables

Variables are organized in `ansible/group_vars/`:

- `all.yml` - Common variables
- `windows.yml` - Windows-specific variables
- `linux.yml` - Linux-specific variables

See [ansible/README.md](ansible/README.md) for detailed variable documentation.

## Usage Examples

### Deploy All Services
```bash
cd ansible
ansible-playbook -i inventory.yml site.yml
```

### Deploy Specific Service
```bash
# Windows Domain Controller
ansible-playbook -i inventory.yml site.yml --limit windows_dc

# Linux Web Stack
ansible-playbook -i inventory.yml site.yml --limit webservers
```

### Test Before Deploying
```bash
# Syntax check
ansible-playbook -i inventory.yml site.yml --syntax-check

# Dry run
ansible-playbook -i inventory.yml site.yml --check
```

## Contributing

When adding new roles or modifying existing ones:

1. Follow the simplified role structure (only `tasks/` and `files/`)
2. Add variables to appropriate `group_vars/` files
3. Update `site.yml` if adding new roles
4. Test with `--check` before committing
5. Update documentation

## License

See [LICENSE](LICENSE) file for details.


## Support

For detailed documentation, see:
- [ansible/README.md](ansible/README.md) - Complete Ansible guide
- Individual role directories for role-specific documentation
