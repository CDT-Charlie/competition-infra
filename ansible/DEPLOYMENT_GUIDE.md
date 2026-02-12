# Deployment Guide

Complete guide for deploying the cyber competition infrastructure.

## Prerequisites

1. **Ansible installed** (2.9+)
2. **Collections installed**:
   ```bash
   ansible-galaxy collection install microsoft.ad
   ansible-galaxy collection install community.windows
   ansible-galaxy collection install community.docker
   ```
3. **Vault file created**:
   ```bash
   ./setup-vault.sh
   ansible-vault edit group_vars/vault.yml  # Change all passwords!
   ```

## Inventory Setup

Edit `inventory.yml` with your hosts:

```yaml
all:
  children:
    windows:
      hosts:
        windows_dc:
          ansible_host: 10.0.100.10
        windows_ldap:
          ansible_host: 10.0.100.11
        windows_fileserver:
          ansible_host: 10.0.100.12
        windows:
          ansible_host: 10.0.100.13
      vars:
        ansible_user: Administrator
        ansible_password: "{{ vault_windows_admin_password }}"
        ansible_connection: winrm
        ansible_winrm_transport: basic
        ansible_winrm_server_cert_validation: ignore
    
    linux:
      children:
        webservers:
          hosts:
            webserver1:
              ansible_host: 10.0.100.20
        mail:
          hosts:
            mailserver1:
              ansible_host: 10.0.100.21
        monitoring_server:
          hosts:
            monitoring1:
              ansible_host: 10.0.100.22
        monitoring_clients:
          hosts:
            client1:
              ansible_host: 10.0.100.23
      vars:
        ansible_user: root
        ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

## Deployment Scenarios

### Scenario 1: Full Deployment

Deploy all services:

```bash
ansible-playbook -i inventory.yml site.yml --ask-vault-pass
```

### Scenario 2: Windows Only

Deploy only Windows services:

```bash
ansible-playbook -i inventory.yml site.yml --limit windows --ask-vault-pass
```

### Scenario 3: Linux Only

Deploy only Linux services:

```bash
ansible-playbook -i inventory.yml site.yml --limit linux --ask-vault-pass
```

### Scenario 4: Individual Roles

Deploy specific roles:

```bash
# Domain Controller
ansible-playbook -i inventory.yml site.yml --limit windows_dc --ask-vault-pass

# Web Stack
ansible-playbook -i inventory.yml site.yml --limit webservers --ask-vault-pass

# Mail Server
ansible-playbook -i inventory.yml site.yml --limit mail --ask-vault-pass
```

## Role-Specific Deployment

### Windows Domain Controller + DNS

```yaml
- name: Deploy DC
  hosts: windows_dc
  roles:
    - win_dc_dns
```

**Requirements:**
- Windows Server 2016+
- Administrative access
- Static IP address

**What it does:**
- Installs AD DS and DNS
- Creates new domain
- Creates OU, group, user

### Windows LDAP + Kerberos

```yaml
- name: Deploy LDAP + Kerberos
  hosts: windows_ldap
  vars:
    join_domain: false  # true to join existing domain
  roles:
    - win_ldap_kerberos
```

**Requirements:**
- Windows Server 2016+
- Administrative access

**What it does:**
- Installs AD DS (provides LDAP + Kerberos)
- Can create new domain or join existing
- Verifies LDAP and Kerberos services

### Windows WinRM

```yaml
- name: Configure WinRM
  hosts: windows
  roles:
    - win_winrm
```

**Requirements:**
- Windows Server or Client
- Administrative access

**What it does:**
- Configures WinRM service
- Creates Ansible user
- Deploys banner

### Windows SMB + FTP

```yaml
- name: Deploy SMB + FTP
  hosts: windows_fileserver
  roles:
    - win_smb_ftp
```

**Requirements:**
- Windows Server or Client
- Administrative access

**What it does:**
- Creates SMB file share
- Configures FTP server
- Sets up persistence (optional)

### Linux Web Stack (Nginx + MySQL)

```yaml
- name: Deploy Web Stack
  hosts: webservers
  become: yes
  roles:
    - nix_web_stack
```

**Requirements:**
- Debian/Ubuntu Linux
- Docker support
- Root/sudo access

**What it does:**
- Installs Docker
- Deploys MySQL container
- Deploys PHP container
- Deploys Nginx container

**Required files** (place in `roles/nix_web_stack/files/`):
- `nginx.conf` - Nginx configuration
- `Dockerfile.php` - PHP Dockerfile

### Linux Mail Server (Postfix + Dovecot)

```yaml
- name: Deploy Mail Server
  hosts: mail
  become: yes
  roles:
    - nix_mail_server
```

**Requirements:**
- Debian/Ubuntu Linux
- Root/sudo access

**What it does:**
- Installs Postfix (SMTP)
- Installs Dovecot (IMAP/POP3)
- Creates SSL certificates
- Configures mail delivery

**Required files** (place in `roles/nix_mail_server/files/`):
- `dovecot.conf` - Dovecot configuration
- `postfix.conf.j2` - Postfix template

### Linux Monitoring (Grafana + rsyslog)

```yaml
# Server mode
- name: Deploy Monitoring Server
  hosts: monitoring_server
  become: yes
  vars:
    rsyslog:
      mode: "server"
  roles:
    - nix_monitoring

# Client mode
- name: Deploy Monitoring Client
  hosts: monitoring_clients
  become: yes
  vars:
    grafana:
      enabled: false
    rsyslog:
      mode: "client"
    syslog_server: "monitoring_server.example.com"
  roles:
    - nix_monitoring
```

**Requirements:**
- Debian/Ubuntu Linux
- Root/sudo access

**What it does:**
- Installs Grafana
- Configures rsyslog (server or client)
- Sets up log rotation (server mode)

## Testing

### Syntax Check

```bash
ansible-playbook -i inventory.yml site.yml --syntax-check
```

### Dry Run

```bash
ansible-playbook -i inventory.yml site.yml --check --ask-vault-pass
```

### Verbose Output

```bash
ansible-playbook -i inventory.yml site.yml -v --ask-vault-pass
```

## Troubleshooting

### Windows Issues

**WinRM connection fails:**
- Ensure WinRM is enabled: `winrm quickconfig`
- Check firewall rules
- Verify credentials

**Domain Controller promotion fails:**
- Ensure DNS is properly configured
- Check for duplicate domain names
- Verify safe mode password meets complexity requirements

### Linux Issues

**Docker issues:**
- Ensure Docker service is running
- Check Docker daemon permissions
- Verify network connectivity

**Service startup fails:**
- Check service logs: `journalctl -u servicename`
- Verify configuration files
- Check file permissions

### Common Issues

**Vault password errors:**
- Verify vault file is encrypted: `ansible-vault view group_vars/vault.yml`
- Check vault password is correct
- Ensure `--ask-vault-pass` is used

**Variable not found:**
- Check variable is defined in `group_vars/`
- Verify variable name spelling
- Check variable precedence

## Post-Deployment Verification

### Windows

```bash
# Check domain controller
ansible windows_dc -i inventory.yml -m win_shell -a "Get-ADDomain"

# Check WinRM
ansible windows -i inventory.yml -m win_ping

# Check services
ansible windows_fileserver -i inventory.yml -m win_service -a "name=WinRM"
```

### Linux

```bash
# Check Docker containers
ansible webservers -i inventory.yml -m shell -a "docker ps"

# Check services
ansible mail -i inventory.yml -m systemd -a "name=postfix"

# Check Grafana
ansible monitoring_server -i inventory.yml -m uri -a "url=http://localhost:3000"
```

## Maintenance

### Updating Passwords

```bash
ansible-vault edit group_vars/vault.yml
```

### Updating Variables

Edit `group_vars/all.yml`, `windows.yml`, or `linux.yml` as needed.

### Adding New Hosts

Add to `inventory.yml` and redeploy:

```bash
ansible-playbook -i inventory.yml site.yml --limit new_hosts --ask-vault-pass
```
