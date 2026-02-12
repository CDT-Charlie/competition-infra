## What this does
This playbook deploys a basic Windows SMB file share (works on Windows client or server):
- Creates a local group + user
- Creates a folder and applies NTFS permissions
- Creates an SMB share and sets share permissions
- Enables File and Printer Sharing firewall rules (included for compatibility)

## Requirements
- Ansible control host (Linux/WSL) with:
  - `ansible-galaxy collection install ansible.windows`
- Windows target reachable over WinRM (default port 5985)

## How to run
1. Edit `inventory.ini` with the Windows IP and admin credentials
2. Run:
   - `ansible -i inventory.ini windows -m ansible.windows.win_ping`
   - `ansible-playbook -i inventory.ini smb_share_windows.yml`

## Customization
Edit variables in `smb_share_windows.yml`:
- `share_name`, `share_path`
- `allowed_group`
- `smb_user`, `smb_password`
