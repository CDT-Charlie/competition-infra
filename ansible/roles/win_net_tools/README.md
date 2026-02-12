# README: Grey Team Windows Lab Staging
**Author: Oliver Gomes (odg1896@rit.edu)**
## Overview
This playbook automates the grey team 'default' deployment of a **Windows Target Machine** for use in an isolated "Grey Team" lab environment. It transforms a base Windows installation into a "glass box" environment, allowing security analysts to observe system behavior and network traffic without the interference of default OS protections for better scoring utility.

## Service
OpenSSH

## Features

- Chocolately
- SysInternals
- Wireshark

#### Would be cool to add later on
- Sysmon

## Why

* **Vulnerability Research:** Test how specific services react to custom exploits without firewall filtering.
* **Real-time Traffic Analysis:** Use Wireshark in conjunction with OpenSSH to remotely trigger and capture network packets to study proprietary protocols.
* **Forensic Monitoring:** Utilize the Sysinternals suite (such as `Procmon` and `Autoruns`) to track file system and registry changes during simulated attacks.


## Prerequisites
* **WinRM Connectivity:** The target machine must be reachable via port 5985 or 5986.
* **Inventory Configuration:** Ensure `win-inventory.ini` contains the correct IP address and `Administrator` credentials.
* **Ansible Collections:** Ensure `community.windows` and `microsoft.ad` collections are installed on your control node.


### 1. Required Ansible Collections
The playbook relies on specific modules that are not included in the Ansible core. You must install the **Community Windows** and **Microsoft AD** collections on your control node before running the playbook:

```bash
# Install the Community Windows collection (for firewall and chocolatey)
ansible-galaxy collection install community.windows

# Install the Microsoft AD collection (for OpenSSH feature management)
ansible-galaxy collection install microsoft.ad
```

## Deployment
To execute the playbook, run the following command from your Ansible control node:

```bash
ansible-playbook -i win-inventory.ini net_tools_no_firewall.yml