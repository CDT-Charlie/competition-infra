# AD Domain Controller / DNS — Ansible Playbook
This folder contains an Ansible automation solution to deploy a Windows **Active Directory Domain Controller** (AD DS) with **DNS**, and provision a basic Organization Unit (OU), group, and user account.

This Ansible playbook:
1. Renames a Windows host
2. Installs the **Active Directory Domain Services** and **DNS Server** roles
3. Promotes the host to a **Domain Controller**
4. Creates:
   - A specific **Organizational Unit**
   - A **security group**
   - A domain **user**
   - Adds the user to the group

### Control Machine
- Ansible 2.11+
- WinRM configured on target Windows host
- Python installed (on control machine)
- Required Ansible Collections:
  ```sh
  ansible-galaxy collection install ansible.windows
  ansible-galaxy collection install microsoft.ad
  ```

Output of the playbook:
```sh
ansible-playbook deploy_dc.yml 
[WARNING]: Collection ansible.windows does not support Ansible version 2.14.18
[WARNING]: Collection microsoft.ad does not support Ansible version 2.14.18

PLAY [Deploy AD] *************************************************************************************************************************************

TASK [Gathering Facts] *******************************************************************************************************************************
ok: [100.65.4.105]

TASK [Set DC hostname] *******************************************************************************************************************************
ok: [100.65.4.105]

TASK [Reboot if hostname change requires it] *********************************************************************************************************
skipping: [100.65.4.105]

TASK [Install Active Directory Domain Services (ADDS)] ***********************************************************************************************
ok: [100.65.4.105]

TASK [Install DNS] ***********************************************************************************************************************************
ok: [100.65.4.105]

TASK [Reboot after ADDS/DNS feature install if needed] ***********************************************************************************************
skipping: [100.65.4.105]

TASK [Create AD domain and reboot] *******************************************************************************************************************
changed: [100.65.4.105]

TASK [Reboot after domain creation / DC promotion if needed] *****************************************************************************************
skipping: [100.65.4.105]

TASK [Create OU] *************************************************************************************************************************************
changed: [100.65.4.105]

TASK [Create group in OU] ****************************************************************************************************************************
changed: [100.65.4.105]

TASK [Create user in OU] *****************************************************************************************************************************
changed: [100.65.4.105]

TASK [Add user to group] *****************************************************************************************************************************
changed: [100.65.4.105]

PLAY RECAP *******************************************************************************************************************************************
100.65.4.105               : ok=9    changed=5    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0   
```
