# Roles Documentation

Complete reference for all standardized roles.

## Role Structure

All roles follow the standard Ansible role structure:

```
role_name/
├── defaults/
│   └── main.yml      # Default variables
├── tasks/
│   └── main.yml      # Main tasks
├── handlers/
│   └── main.yml      # Handlers (if needed)
├── templates/        # Jinja2 templates (if needed)
├── files/            # Static files (if needed)
└── README.md         # Role documentation
```

## Windows Roles

### win_dc_dns

**Purpose:** Deploy Windows Domain Controller with DNS

**Deploys:**
- Active Directory Domain Services (AD DS)
- DNS Server
- Domain creation
- OU, group, and user creation

**Key Variables:**
- `dc_hostname`: DC hostname
- `domain_name`: Domain FQDN
- `safe_mode_password`: DSRM password

**Dependencies:**
- `microsoft.ad` collection

**Example:**
```yaml
- hosts: windows_dc
  roles:
    - win_dc_dns
```

### win_ldap_kerberos

**Purpose:** Deploy Windows server with LDAP + Kerberos (AD DS)

**Deploys:**
- Active Directory Domain Services
- LDAP directory services
- Kerberos authentication
- Can create new domain or join existing

**Key Variables:**
- `join_domain`: Join existing domain (true/false)
- `domain_name`: Domain FQDN
- `ldap.*`: LDAP configuration
- `kerberos.*`: Kerberos configuration

**Dependencies:**
- `microsoft.ad` collection

**Example:**
```yaml
- hosts: windows_ldap
  vars:
    join_domain: false
  roles:
    - win_ldap_kerberos
```

### win_winrm

**Purpose:** Configure WinRM and Ansible management environment

**Deploys:**
- WinRM service configuration
- Ansible user account
- Login banner
- Service monitoring

**Key Variables:**
- `ansible_user.*`: Ansible user configuration
- `banner.*`: Banner configuration
- `monitored_service`: Service to monitor

**Dependencies:** None

**Example:**
```yaml
- hosts: windows
  roles:
    - win_winrm
```

### win_smb_ftp

**Purpose:** Deploy SMB file share and FTP server

**Deploys:**
- SMB file share
- FTP server (IIS-based)
- User/group management
- Firewall rules
- Optional persistence

**Key Variables:**
- `smb.*`: SMB share configuration
- `ftp.*`: FTP server configuration

**Dependencies:**
- `community.windows` collection

**Example:**
```yaml
- hosts: windows_fileserver
  roles:
    - win_smb_ftp
```

## Linux Roles

### nix_web_stack

**Purpose:** Deploy Nginx + MySQL web stack using Docker

**Deploys:**
- Docker
- MySQL container
- PHP container
- Nginx container
- Database initialization

**Key Variables:**
- `web.*`: Web directory configuration
- `docker.*`: Docker container configuration
- `database.*`: Database configuration

**Dependencies:**
- `community.docker` collection

**Required Files:**
- `files/nginx.conf`
- `files/Dockerfile.php`

**Example:**
```yaml
- hosts: webservers
  become: yes
  roles:
    - nix_web_stack
```

### nix_mail_server

**Purpose:** Deploy Postfix + Dovecot mail server

**Deploys:**
- Postfix (SMTP)
- Dovecot (IMAP/POP3)
- SSL/TLS certificates
- Service accounts

**Key Variables:**
- `ssl.*`: SSL certificate configuration
- `postfix.*`: Postfix configuration
- `dovecot.*`: Dovecot configuration

**Dependencies:** None

**Required Files:**
- `files/dovecot.conf`
- `templates/postfix.conf.j2`

**Example:**
```yaml
- hosts: mail
  become: yes
  roles:
    - nix_mail_server
```

### nix_monitoring

**Purpose:** Deploy Grafana monitoring and rsyslog logging

**Deploys:**
- Grafana dashboard
- rsyslog (server or client mode)
- Log rotation (server mode)

**Key Variables:**
- `grafana.*`: Grafana configuration
- `rsyslog.*`: rsyslog configuration
- `syslog_server`: Central server (client mode)

**Dependencies:** None

**Example:**
```yaml
# Server mode
- hosts: monitoring_server
  become: yes
  vars:
    rsyslog:
      mode: "server"
  roles:
    - nix_monitoring

# Client mode
- hosts: monitoring_clients
  become: yes
  vars:
    rsyslog:
      mode: "client"
    syslog_server: "monitoring.example.com"
  roles:
    - nix_monitoring
```

## Role Comparison

| Role | OS | Services | Complexity |
|------|----|----------|-----------| 
| win_dc_dns | Windows | AD DS, DNS | High |
| win_ldap_kerberos | Windows | AD DS (LDAP + Kerberos) | High |
| win_winrm | Windows | WinRM | Low |
| win_smb_ftp | Windows | SMB, FTP | Medium |
| nix_web_stack | Linux | Nginx, MySQL, PHP | Medium |
| nix_mail_server | Linux | Postfix, Dovecot | Medium |
| nix_monitoring | Linux | Grafana, rsyslog | Low |

## Best Practices

1. **Use centralized variables** from `group_vars/`
2. **Override in playbooks** only when necessary
3. **Test with `--check`** before deploying
4. **Use vault** for all passwords
5. **Document customizations** in role READMEs
6. **Follow naming conventions** consistently
7. **Handle reboots** properly (Windows roles)
8. **Use handlers** for service restarts
9. **Idempotency** - roles should be safe to run multiple times
10. **Error handling** - use `ignore_errors` and `failed_when` appropriately

## Role Development

When creating new roles:

1. Follow standard directory structure
2. Use `defaults/main.yml` for variables
3. Reference centralized `group_vars/`
4. Use handlers for service restarts
5. Add comprehensive README
6. Test with `--check` and `--diff`
7. Document all variables
8. Include examples
