# Windows WinRM Role

Configures WinRM service and sets up Ansible management environment on Windows hosts.

## Features

- Configures WinRM service (enabled and running)
- Creates Ansible user account
- Adds Ansible user to Administrators group
- Deploys login banner
- Ensures monitored service is running

## Requirements

- Windows Server or Windows Client
- Ansible 2.9+
- Administrative access to Windows host

## Role Variables

All variables use centralized `group_vars/all.yml` by default. See `defaults/main.yml` for role-specific defaults.

### Key Variables

- `winrm_service_name`: WinRM service name (default: "WinRM")
- `ansible_user`: Dictionary with username, password, and groups
- `banner`: Banner configuration (enabled, directory, filename, text)
- `monitored_service`: Service name to ensure is running

## Dependencies

None

## Example Playbook

```yaml
- name: Configure WinRM
  hosts: windows
  roles:
    - win_winrm
```

## Notes

- The Ansible user is created with password never expires
- Banner is optional and can be disabled by setting `banner.enabled: false`
