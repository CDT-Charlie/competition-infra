# Red team Ansible — SSH on victim VMs

Setup SSH servers on all victim VMs (Linux and Windows) so you can SSH from Kali or your workstation.

## Prerequisites

- Ansible 2.14+ with collections: `ansible.windows`, `ansible.posix`
- For Windows: WinRM reachable (default; used to install OpenSSH the first time)
- For Linux: SSH access with a user that can sudo (e.g. `ubuntu` or `debian`)

Install collections:

```bash
ansible-galaxy collection install ansible.windows ansible.posix
```

## Inventory

`inventory.yml` lists victim IPs. If you change `terraform.tfvars`, update the IPs here (or use Terraform output):

```bash
cd .. && terraform output -json victim_ips
```

## Running the playbook

From this directory:

```bash
# Linux only (no Windows credentials needed)
ansible-playbook -i inventory.yml playbook-ssh.yml --limit linux_victims

# Windows only (pass admin credentials; WinRM is used for the first run)
ansible-playbook -i inventory.yml playbook-ssh.yml --limit windows_victims \
  -e ansible_user=Administrator -e ansible_password='YOUR_WINDOWS_ADMIN_PASSWORD'

# All victims
ansible-playbook -i inventory.yml playbook-ssh.yml \
  -e ansible_user=Administrator -e ansible_password='YOUR_WINDOWS_ADMIN_PASSWORD'
```

For Linux, set `ansible_user` and/or `ansible_ssh_private_key_file` in `group_vars/linux_victims.yml` if your images use a different user or key than the Terraform key.

After the playbook runs, Windows victims will have OpenSSH Server listening on port 22; you can then use SSH (e.g. `ssh Administrator@192.168.0.23`) in addition to WinRM.
