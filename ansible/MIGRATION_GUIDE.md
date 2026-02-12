# Migration Guide: Updating Playbooks to Use Centralized Variables

This guide shows how to migrate existing playbooks to use the new centralized variable structure.

## Quick Start

1. **Create the vault file** (see VARIABLES.md)
2. **Update playbooks** to reference centralized variables
3. **Remove hardcoded values** from playbooks
4. **Test** with `--check` before deploying

## Step-by-Step Migration Examples

### Example 1: Grafana Playbook

**Before (`roles/nix_grafana/grafana.yml`):**
```yaml
vars:
  grafana_http_port: 3000
  grafana_domain: "CharlieGreyTeam"
  grafana_root_url: "http://{{grafana_domain}}: {{grafana_http_port}}/"
  grafana_admin_user: admin
  grafana_admin_password: "Password123!" # change this!!
```

**After:**
```yaml
# Variables are now in group_vars/all.yml
# No vars section needed, or minimal override:
vars:
  # Only override if needed for this specific playbook
  # Otherwise use: applications.grafana.*
```

**Updated tasks:**
```yaml
- name: Configure grafana.ini
  lineinfile:
    path: /etc/grafana/grafana.ini
    regexp: "^;?{{ item.key }} ="
    line: "{{ item.key }} = {{ item.value }}"
  loop:
    - { key: "http_port", value: "{{ applications.grafana.http_port }}" }
    - { key: "domain", value: "{{ applications.grafana.domain }}" }
    - { key: "root_url", value: "{{ applications.grafana.root_url }}" }
```

### Example 2: Windows Domain Controller

**Before (`roles/win_deploy_dc/deploy_dc.yml`):**
```yaml
vars:
  domain_name: "hockey.cdtcharlie.com"
  netbios_name: "HOCKEY1"
  safe_mode_password: "Password123!"
  dc_hostname: "DC1"
  ou_name: "GreyTeam"
  group_name: "BlueTeamAdmins"
  user_sam: "alice"
  user_given: "Alice"
  user_surname: "Operator"
  user_password: "ChangeMe_User123!"
```

**After:**
```yaml
# All variables now in group_vars/all.yml under windows_domain.*
# No vars section needed
```

**Updated tasks:**
```yaml
- name: Create AD domain
  microsoft.ad.domain:
    dns_domain_name: "{{ windows_domain.domain_name }}"
    domain_netbios_name: "{{ windows_domain.netbios_name }}"
    safe_mode_password: "{{ windows_domain.safe_mode_password }}"
    # ...

- name: Create user in OU
  microsoft.ad.user:
    name: "{{ windows_domain.domain_user.sam }}"
    firstname: "{{ windows_domain.domain_user.given }}"
    lastname: "{{ windows_domain.domain_user.surname }}"
    password: "{{ windows_domain.domain_user.password }}"
    # ...
```

### Example 3: LDAP Setup

**Before (`roles/win_ldap/vars/ldap.yml`):**
```yaml
ldap_suffix: "dc=example,dc=com"
ldap_admin_dn: "cn=admin,dc=example,dc=com"
ldap_admin_password: "Password"
ldap_rootdn: "cn=admin,dc=example,dc=com"
ldap_rootpw: "Password"
```

**After:**
```yaml
# File can be removed - variables now in group_vars/all.yml
# Reference: applications.ldap.*
```

**Updated playbook:**
```yaml
- name: LDAP Setup
  vars:
    # Reference centralized variables
    ldap_admin_dn: "{{ applications.ldap.admin_dn }}"
    ldap_admin_password: "{{ applications.ldap.admin_password }}"
    ldap_rootdn: "{{ applications.ldap.root_dn }}"
    ldap_rootpw: "{{ applications.ldap.root_password }}"
```

### Example 4: MySQL/Docker Web Stack

**Before (`roles/nix_nginx_container/web-stack.yml`):**
```yaml
env:
  MYSQL_ROOT_PASSWORD: examplepassword
```

**Before (`roles/nix_nginx_container/init.sql`):**
```sql
CREATE USER IF NOT EXISTS 'greyteam'@'%' IDENTIFIED BY 'testpass';
```

**After:**
```yaml
- name: Run MySQL Container
  docker_container:
    name: mysql
    image: mysql:latest
    env:
      MYSQL_ROOT_PASSWORD: "{{ docker.mysql_root_password }}"
      MYSQL_DATABASE: "{{ database.app_user }}"
      MYSQL_USER: "{{ docker.mysql_app_user }}"
      MYSQL_PASSWORD: "{{ docker.mysql_app_password }}"
```

**Updated init.sql:**
```sql
CREATE USER IF NOT EXISTS '{{ database.app_user }}'@'%' IDENTIFIED BY '{{ database.app_password }}';
-- Note: This requires using a template file instead of static SQL
```

**Better approach - use template:**
```yaml
- name: Generate init.sql from template
  template:
    src: init.sql.j2
    dest: /opt/web/init.sql
```

### Example 5: Windows SMB Share

**Before (`roles/win_SMB/smb_share_windows.yml`):**
```yaml
vars:
  share_name: "CDTShare"
  share_path: "C:\\CDTShare"
  allowed_group: "CDTShareUsers"
  smb_user: "cdtshareuser"
  smb_password: "P@ssw0rd!ChangeMe123"
```

**After:**
```yaml
# Variables now in group_vars/all.yml and group_vars/windows.yml
vars:
  share_name: "{{ competition_team }}Share"
  share_path: "{{ windows_paths.smb_share }}"
  allowed_group: "{{ applications.smb.share_group }}"
  smb_user: "{{ applications.smb.share_user }}"
  smb_password: "{{ applications.smb.share_password }}"
```

## Migration Checklist

For each playbook:

- [ ] Identify all hardcoded values (passwords, usernames, domains, paths)
- [ ] Check if variable exists in `group_vars/all.yml`, `windows.yml`, or `linux.yml`
- [ ] If not, add to appropriate group_vars file
- [ ] Move passwords to `vault.yml`
- [ ] Update playbook to reference centralized variables
- [ ] Remove local `vars:` sections or minimize to overrides only
- [ ] Update any template files (`.j2`) to use variables
- [ ] Test with `ansible-playbook --check`
- [ ] Test with `ansible-playbook --ask-vault-pass`

## Common Patterns

### Pattern 1: Simple Variable Replacement

**Before:**
```yaml
vars:
  password: "hardcoded123"
```

**After:**
```yaml
# Remove vars section, use:
# {{ vault_service_password }}
```

### Pattern 2: Nested Variables

**Before:**
```yaml
vars:
  admin_user: "admin"
  admin_pass: "Password123!"
```

**After:**
```yaml
# Use:
# {{ standard_users.admin.username }}
# {{ standard_users.admin.password }}
```

### Pattern 3: OS-Specific Variables

**Before:**
```yaml
vars:
  user: "Administrator"  # Windows
  user: "root"           # Linux
```

**After:**
```yaml
# Use conditionals or OS-specific vars:
- name: Create user
  when: ansible_os_family == "Windows"
  vars:
    user: "{{ windows_users.administrator.username }}"

- name: Create user
  when: ansible_os_family == "RedHat" or ansible_os_family == "Debian"
  vars:
    user: "{{ linux_users.admin.username }}"
```

## Testing After Migration

1. **Syntax check:**
   ```bash
   ansible-playbook playbook.yml --syntax-check
   ```

2. **Dry run:**
   ```bash
   ansible-playbook playbook.yml --check --ask-vault-pass
   ```

3. **Full test:**
   ```bash
   ansible-playbook playbook.yml --ask-vault-pass
   ```

## Rollback Plan

If issues occur:

1. Keep original playbooks in a backup branch
2. Use git to revert changes if needed
3. Test migrations incrementally (one playbook at a time)
4. Document any custom variables that don't fit the standard structure

## Next Steps

After migrating all playbooks:

1. Update inventory files to remove hardcoded credentials
2. Create host_vars for host-specific overrides if needed
3. Document any custom variables in VARIABLES.md
4. Set up CI/CD to use vault password file securely
5. Rotate all passwords in vault.yml
