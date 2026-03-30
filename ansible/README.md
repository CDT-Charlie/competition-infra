# Ansible Infrastructure Deployment

This directory contains Ansible playbooks and roles for deploying cyber competition infrastructure across Windows and Linux systems.

## Role Structure

Most roles use a small layout with `tasks/` (and `files/` when needed). Some roles also ship **`defaults/main.yml`** or **`handlers/main.yml`** (for example **`nix_grafana`**).

```
role_name/
├── tasks/
│   └── main.yml      # Role entrypoint (may include_tasks other YAML in the same folder)
├── handlers/         # Optional (e.g. service restarts)
├── defaults/         # Optional (fallback variables)
└── files/            # Static files (if needed)
```

## Quick Start

### Prerequisites

1. **Install Ansible** (2.9+)
   ```bash
   sudo apt install ansible -y
   ```
2. **Install OpenStack Package**
   ```bash
   sudo apt install python3-openstackclient
   ```

3. **Install Required Collections**
   ```bash
   ansible-galaxy collection install -r requirements.yml
   ```
   That installs the versions listed in `requirements.yml` (Windows, Microsoft AD, Docker, etc.).

4. **Configure Inventory**
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

`inventory.yml` is the primary Blue Team competition inventory (including user provisioning).

`site.yml` defaults Domain Controller deployment scope to each DC host's own team (`dc_team`), so no extra argument is required for normal runs.

### Active Directory / domain join (Windows + Linux, one playbook)

After **WinRM bootstrap** and **DC promotion** (`win_dc_dns`), `site.yml` joins **all** member Windows hosts (`blue_windows:!windows_dc`) and **all** Blue Linux hosts (`blue_linux`) to the domain—one command for both OS families.

**Variables:** `windows_ad_domain_join` and per-team **`team_domain_controller`**, **`team_domain_controller_ip`**, and `ad_domain` / `ad_domain_join` (see `group_vars/blue_team_*_{linux,windows}.yml`). `win_domain_join` uses the DC **FQDN** for `microsoft.ad.membership`’s `domain_server` (not the IP alone). Linux uses `nix_ad_domain_join` in `group_vars/blue_linux.yml`.

**WinRM on domain controllers (bardown):** After DCPromo, local **`ansible`** is usually rejected (`ntlm: credentials were rejected`). **`windows_dc_winrm_use_domain_account`** in **`all.yml`** defaults to **`true`** so Ansible uses **`LAKEPLACID\greyteam`** (from **`ad_domain_join`**) on DCs. Set **`false`** only for the **first** `win_dc_dns` run on a workgroup server, then set **`true`** again (or use `-e windows_dc_winrm_use_domain_account=false` once).

**Linux SSH vs AD join:** Ansible uses **`bootstrap_user`** (**cyberrange**) for SSH and `sudo`; AD join auth uses **`ad_domain_join`** (**greyteam**). The Linux preflight configures split DNS with `resolvectl domain ~{{ ad_domain }}` and preserves OpenStack DNS. If `openstack_dns_servers` is set (list), those are used as upstream resolvers; otherwise it queries per-link DNS from `resolvectl`.

**Linux AD preflight checks (actionable failures):** DNS config application, AD A/SRV lookups, TCP 53/88/389, `adcli info --domain-controller=<team_dc_ip>`, and `realm discover`. Join defaults to `realm join` (DNS-based discovery, no unsupported `--server` flags). For strict per-DC targeting use `-e nix_ad_join_method=adcli` (uses `adcli join --domain-controller=<team_dc_ip>`).

**If apt cache fails before join:** set `openstack_dns_servers` in `group_vars/all.yml` so non-AD DNS still resolves package mirrors while AD lookups route to team DC. Example:
`openstack_dns_servers: ["10.0.0.2","10.0.0.3"]`

**Windows temp cleanup warnings:** `Failure cleaning temp path … Incorrect function` / `NtSetInformationFile` are often benign (upgrade `ansible.windows` if noisy). Avoid custom **`ansible_remote_tmp`** under **`C:\Windows\Temp\...`** unless that folder exists — it can cause `DirectoryNotFoundException` during facts.

**Domain stack only** (no scored SMB/web/mail/Grafana/rsyslog plays):

```bash
ansible-playbook -i inventory.yml site.yml --tags domain_stack
```

**Full stack** (default) runs `domain_stack` plays and then **`services`**-tagged plays.

Optional override for DC/DNS scope:
```bash
# Team 1 only
ansible-playbook -i inventory.yml site.yml -e windows_dc_deployment_team=blue_team_1

# Team 2 only
ansible-playbook -i inventory.yml site.yml -e windows_dc_deployment_team=blue_team_2
```

### Deploy Specific Service

```bash
# Windows bootstrap (WinRM/base)
ansible-playbook -i inventory.yml site.yml --limit windows

# Windows Domain Controller / DNS
ansible-playbook -i inventory.yml site.yml --limit windows_dc

# Windows SMB service
ansible-playbook -i inventory.yml site.yml --limit windows_fileserver

# Linux Web Stack (Nginx/MySQL stack role)
ansible-playbook -i inventory.yml site.yml --limit webservers

# Linux Grafana service
ansible-playbook -i inventory.yml site.yml --limit monitoring_server

# Linux rsyslog central service
ansible-playbook -i inventory.yml site.yml --limit syslog_central
```

### Deploy SSH public keys (Linux)

**Reach the host before you fix passwords or keys.** If Ansible reports **UNREACHABLE**, **Connection timed out**, or **No route to host**, the control machine often cannot open **TCP 22** to **`ansible_host`**. That is separate from “wrong password” or **AuthenticationMethods**.

On **each Linux VM you cannot reach** (use the VM console, hypervisor, or physical access—**not** SSH):

1. **Install and start SSH** (Ubuntu Desktop does not always have a listening SSH server until you add it):
   ```bash
   sudo apt update
   sudo apt install -y openssh-server
   sudo systemctl enable --now ssh
   ```
2. **Confirm sshd is listening on the network**, not only loopback:
   ```bash
   ss -tlnp | grep ':22'
   ```
   You want **`0.0.0.0:22`** or **`[::]:22`**. If nothing listens, check **`sudo systemctl status ssh`** and logs: **`journalctl -u ssh -e`**.
3. **Firewall:** if **UFW** is enabled, allow SSH:
   ```bash
   sudo ufw allow OpenSSH
   # or: sudo ufw allow 22/tcp
   sudo ufw reload
   sudo ufw status
   ```
4. **Inventory and network:** `inventory.yml` → **`ansible_host`** must be an IP (or DNS name) that the **Ansible controller can route to**. OpenStack/security groups, campus Wi‑Fi client isolation, or wrong VLAN will block traffic even when sshd is fine on the VM.

From the **control node** (quick checks):

```bash
nc -vz <ansible_host> 22
ssh -v cyberrange@<ansible_host>
```

If **`nc`** fails with timeout or “Connection refused”, fix **SSH install / listen address / firewall / cloud SG / routing** on the VM or network first; only then use **`deploy-ssh-keys.sh`** and the password-vs-pubkey notes below.

---

Before relying on key-based SSH for Blue Team Linux hosts, push your controller’s public key onto the **`bootstrap_user`** account (see `group_vars/all.yml` → `bootstrap_user`, typically **`cyberrange`** with the password from `group_vars/blue_linux.yml`).

**Default behavior:** the playbook adds **`-o PreferredAuthentications=password -o PubkeyAuthentication=no`** so Ansible can log in with **only the password** (no key on the controller yet). That matches typical server images.

**Hosts that require public key *and* password:** some desktops or hardened images set sshd **`AuthenticationMethods publickey,password`** (both). Then a client that disables pubkey **cannot** authenticate, so manual tests like `ssh -o PubkeyAuthentication=no cyberrange@…` will always fail. For those hosts you must either:

- **One-time relax sshd** (console): e.g. set **`AuthenticationMethods any`** or **`password`** until keys are deployed, then restore policy; or  
- **Use an identity already in `authorized_keys`** on the VM: run the deploy playbook with **`deploy_ssh_force_password_only=false`** and pass **`ansible_ssh_private_key_file`** for that private key. Ansible will use **pubkey + password** (still needs **`sshpass`** for the password leg when `ansible_password` is set).

**Control node prerequisite:** install **`sshpass`** on the machine where you run Ansible whenever **`ansible_password`** is used. Without it, you will see: *“you must install the sshpass program”*.

```bash
# Debian / Ubuntu
sudo apt install -y sshpass

# RHEL / Fedora
sudo dnf install -y sshpass
```

**Playbook:** `deploy_ssh_key.yml`  
**Defaults:** hosts = inventory group **`blue_linux`** (override with **`-e target_group=…`**), key file passed explicitly or chosen by the helper script.

**Helper script:** `ansible/scripts/deploy-ssh-keys.sh`. It changes into `ansible/` before running the playbook, so you can invoke it from `ansible/` as `./scripts/deploy-ssh-keys.sh` or from the repo root as `ansible/scripts/deploy-ssh-keys.sh`.

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
cd ansible
chmod +x scripts/deploy-ssh-keys.sh
./scripts/deploy-ssh-keys.sh ~/.ssh/id_ed25519.pub
INVENTORY=my-inventory.yml ./scripts/deploy-ssh-keys.sh
./scripts/deploy-ssh-keys.sh -- --limit blue_team_1_linux
```

**Multi-method sshd** (pubkey + password required): use a private key that is **already trusted** on the target, and allow pubkey in SSH options:

```bash
cd ansible
DEPLOY_SSH_FORCE_PASSWORD_ONLY=false \
ANSIBLE_SSH_PRIVATE_KEY_FILE=~/.ssh/image_bootstrap_key \
  ./scripts/deploy-ssh-keys.sh ~/.ssh/id_ed25519.pub
```

Or with `ansible-playbook` directly:

```bash
ansible-playbook -i inventory.yml deploy_ssh_key.yml \
  -e ssh_public_key_file=$HOME/.ssh/id_ed25519.pub \
  -e deploy_ssh_force_password_only=false \
  -e ansible_ssh_private_key_file=$HOME/.ssh/image_bootstrap_key
```

The script sets **`SSH_PUBLIC_KEY_FILE`**, tries common paths (`~/.ssh/id_ed25519.pub`, `id_rsa.pub`, and Windows **`USERPROFILE`**), and passes **`target_group`** (default **`blue_linux`**, overridable with env **`TARGET_GROUP`**) into the playbook.

**Manual run:**

```bash
cd ansible
ansible-playbook -i inventory.yml deploy_ssh_key.yml -e ssh_public_key_file=$HOME/.ssh/id_ed25519.pub
ansible-playbook -i inventory.yml deploy_ssh_key.yml -e ssh_public_key_file=$HOME/.ssh/id_ed25519.pub -e target_group=blue_team_2_linux
```

Afterward, point Ansible at your private key, for example:

```bash
ansible-playbook -i inventory.yml site.yml --private-key ~/.ssh/id_ed25519
```

Or set **`ansible_ssh_private_key_file`** in `group_vars/blue_linux.yml` (or host vars) so you do not need **`--private-key`** every time.

### Standalone Role Playbook

```bash
# Domain Controller + DNS role wrapper
ansible-playbook -i inventory.yml roles/win_dc_dns/deploy_dc.yml

# Domain Controller + DNS role wrapper (team specific)
ansible-playbook -i inventory.yml roles/win_dc_dns/deploy_dc.yml -e windows_dc_deployment_team=blue_team_1
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
- Creates OU, optional custom group (`BlueTeamAdmins`), and domain users; privileged roster users go to **Domain Admins**

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

#### `nix_mail`
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

#### `nix_grafana`
**Purpose:** Install Grafana from the official APT repo and tune core `[server]` settings.

**Deploys:**
- Prerequisite packages (`apt-transport-https`, `ca-certificates`, `curl`, `gnupg`)
- Grafana signing key under `/usr/share/keyrings/grafana.asc` and `deb [signed-by=…] https://apt.grafana.com stable main`
- `grafana` package
- `grafana.ini` lines for **`http_port`**, **`domain`**, and **`root_url`** (via `ansible.builtin.lineinfile`)
- Optional **`GF_SECURITY_ADMIN_*`** in `/etc/default/grafana-server` when that file exists (after package install)
- `grafana-server` enabled and started; handler restarts on config changes

**Variables:** `site.yml` maps `group_vars/linux.yml` → `grafana` into flat role vars: `grafana_http_port`, `grafana_domain`, `grafana_root_url`, `grafana_admin_user`, `grafana_admin_password`. Defaults are in `roles/nix_grafana/defaults/main.yml`.

**Inventory Group:** `monitoring_server` (see `site.yml`; Grafana play also enables **`nix_rsyslog`** in server mode on the same hosts if you want a combined monitoring + log receiver).

#### `nix_rsyslog`
**Purpose:** Centralized rsyslog—**one TCP receiver** and clients that forward everything to it.

**Task layout:** Implementations live in split files under `roles/nix_rsyslog/tasks/`:
- **`c_syslog.yml`** — central server: install/enable rsyslog, `/var/log/remote`, **imtcp** listener on **port 514**, per-host/program log paths, drop noisy **ansible** program logs, **logrotate** for remote logs (size **100k**, **hourly**, compress, two rotations).
- **`cli_syslog.yml`** — clients: install/enable rsyslog, **`90-forward.conf`** forwarding **`*.*`** via TCP (`@@`) to the first host in inventory group **`syslog_central`**.

Those files were written as standalone plays (`hosts: syslog_central` / `hosts: syslog_clients`). **`site.yml`** drives the same behavior through inventory groups and the play variable **`rsyslog_mode`** (`"server"` or `"client"`): `syslog_central`, `monitoring_server` (with `rsyslog_mode: "server"`), and `blue_linux:!syslog_central` (client). For the role to run correctly when included by `site.yml`, **`tasks/main.yml` must `include_tasks` the server or client task list according to `rsyslog_mode`** (or inline equivalent tasks). See also `roles/nix_rsyslog/README.md` for paths and rotation behavior.

**Variables:** Optional tuning in `group_vars/linux.yml` → `rsyslog`; forwarding resolution requires at least one host in **`syslog_central`** so clients can target `groups['syslog_central'][0]`.

**Inventory groups (typical):**
- **`syslog_central`** / **`monitoring_server`** — receiver (`rsyslog_mode: "server"`)
- **`blue_linux:!syslog_central`** — forwarders (`rsyslog_mode: "client"`)

## Variable Management

### Variable Files

Variables are organized in `group_vars/`:

- **`all.yml`** - Common variables for all hosts
- **`windows.yml`** - Windows-specific variables
- **`linux.yml`** - Linux-specific variables
- **`blue_linux.yml`** - Blue Team Linux connection/bootstrap (`cyberrange`) and `nix_ad_domain_join`
- **`blue_windows.yml`** - Blue Team Windows WinRM settings
- **`blue_team_1_linux.yml`** / **`blue_team_2_linux.yml`** - Team DC IP for DNS/realm, roster name lists (reference)
- **`blue_team_1_windows.yml`** / **`blue_team_2_windows.yml`** - Team DC IP, `windows_ad_domain_join`, `windows_domain_team_users` for the DC role

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
  root_url: "http://CharlieGreyTeam:3000/"
  admin_user: "admin"
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
- `windows_fileserver` - SMB/FTP servers
- `windows` - General Windows hosts (WinRM)
- `windows_iis` - Reserved group for future IIS role

### Linux
- `mcp_hosts` - Reserved group for future MCP role
- `webservers` - Web stack hosts
- `mail` - Mail servers
- `monitoring_server` - Grafana + rsyslog server (`nix_grafana` + `nix_rsyslog`)
- `syslog_central` - Dedicated rsyslog **receiver** (TCP 514; logs under `/var/log/remote/` on that host)

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

1. **Simple Structure** - Prefer `tasks/` and `files/`; add `handlers/` or `defaults/` when a role needs them
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

## Notes

- All passwords are currently in plain text in `group_vars/` files
- Consider implementing Ansible Vault for production use
- Old role directories may still exist for reference (can be removed after verification)
- Some roles may have old playbook files alongside new role structure (for reference)

## Support

For role-specific documentation, see individual role directories. Each role should have a `README.md` with detailed information.
