# CSEC-473 HW2 – Ansible (WinRM + Features)

**Author:** Christian Tomassetti  
**Date:** 2026-02-04  
**Service:** WinRM (Windows Remote Management)

## What this does
This project contains an Ansible playbook that manages a Windows Server 2022 target via WinRM.

### Service
- Ensures **WinRM** is enabled and running (required for Windows Ansible management)

### Features (3)
1. Creates a local user and adds it to **Administrators**
2. Deploys a banner file to `C:\ProgramData\csec473\banner.txt`
3. Ensures a chosen Windows service is set to **Automatic** and **Running**

## Files
- `winrm-deploy.yml` – main playbook
- `win-inventory.ini` – inventory (update target IP/credentials)

## Requirements
- Debian 12 controller with Ansible installed
- Windows Server 2022 target reachable over WinRM (typically port 5985)

## Customization
Edit variables at the top of `winrm-deploy.yml`:
- `new_user`, `new_pass`
- `banner_text`
- `service`

## Run
```bash
ansible-playbook -i win-inventory.ini winrm-deploy.yml
