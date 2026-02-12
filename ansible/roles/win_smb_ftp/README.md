# Windows SMB + FTP Role

Deploys SMB file share and FTP server on Windows hosts.

## Features

### SMB Share
- Creates SMB file share
- Creates local group and user for share access
- Configures NTFS permissions
- Opens firewall rules

### FTP Server
- Installs FTP server components (IIS-based)
- Creates FTP site
- Configures anonymous authentication
- Opens firewall rules
- Optional persistence mechanism via scheduled task

## Requirements

- Windows Server or Windows Client
- Ansible 2.9+
- `community.windows` collection installed
- Administrative access to Windows host

## Role Variables

All variables use centralized `group_vars/all.yml` by default. See `defaults/main.yml` for role-specific defaults.

### SMB Variables

- `smb.share_name`: Name of the SMB share
- `smb.share_path`: Path to share directory
- `smb.allowed_group`: Group allowed to access share
- `smb.user`: User account for share access

### FTP Variables

- `ftp.enabled`: Enable/disable FTP (default: true)
- `ftp.site_name`: FTP site name
- `ftp.root_path`: FTP root directory
- `ftp.port`: FTP port (default: 2121)
- `ftp.anonymous_auth`: Enable anonymous authentication
- `ftp.persistence`: Persistence configuration

## Dependencies

- `community.windows` collection

## Example Playbook

```yaml
- name: Deploy SMB and FTP
  hosts: windows_fileserver
  roles:
    - win_smb_ftp
```

## Notes

- FTP persistence creates a scheduled task that runs every 15 minutes
- SMB share is configured with Modify permissions for the allowed group
- Both services automatically configure firewall rules
