# AD Domain Controller / DNS — Ansible Role
This role deploys Windows **Active Directory Domain Services** (AD DS) + **DNS** for the competition domain and supports Team 1 / Team 2 / all-team deployments from one unified workflow.

The role now:
1. Installs AD DS + DNS features
2. Creates or ensures the `lakeplacid.local` domain
3. Creates the competition OU and security group
4. Creates all required domain users (shared + team-specific)
5. Adds admin-designated domain users (`is_admin: true` in `windows_domain_team_users`) to **Domain Admins**
6. Creates DNS A records for team hosts based on selected deployment scope

### Control Machine
- Ansible 2.11+
- WinRM configured on target Windows host
- Python installed (on control machine)
- Required Ansible Collections:
  ```sh
  ansible-galaxy collection install ansible.windows
  ansible-galaxy collection install microsoft.ad
  ```

## Deployment Commands
From `ansible/`:

You can also run through the main playbook:
```sh
ansible-playbook -i inventory.yml site.yml -e windows_dc_deployment_team=blue_team_1
```

### Windows DC DNS Deployment
Deploy both teams:
```sh
ansible-playbook -i inventory.yml roles/win_dc_dns/deploy_dc.yml -e windows_dc_deployment_team=all
```

Deploy Team 1 only:
```sh
ansible-playbook -i inventory.yml roles/win_dc_dns/deploy_dc.yml -e windows_dc_deployment_team=blue_team_1
```

Deploy Team 2 only:
```sh
ansible-playbook -i inventory.yml roles/win_dc_dns/deploy_dc.yml -e windows_dc_deployment_team=blue_team_2
```