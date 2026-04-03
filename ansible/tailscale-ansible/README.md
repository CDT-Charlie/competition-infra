# Tailscale Ansible Deployment

Deploys the Tailscale daemon to 12 Linux and 6 Windows hosts.

## First-Time Setup

### 1. Create your Vault password file
```bash
echo "your_strong_vault_password" > ~/.vault_pass
chmod 600 ~/.vault_pass
```
Keep this password somewhere safe (e.g. a password manager). Anyone running
these playbooks will need it.

### 2. Edit secrets.yml with your Tailscale auth key
```bash
ansible-vault edit secrets.yml
```
Set the value:
```yaml
tailscale_authkey: "tskey-auth-YOURKEY"
```

### 3. If starting fresh (secrets.yml is plaintext), encrypt it
```bash
ansible-vault encrypt secrets.yml
```
Once encrypted, secrets.yml is safe to commit. It will look like:
```
$ANSIBLE_VAULT;1.1;AES256
61613364336234623061653364653234...
```

### 4. Update inventory.ini
Replace the placeholder IPs with your real host IPs.

### 5. Update group_vars
- `group_vars/linux.yml` — set your SSH user and key path
- `group_vars/windows.yml` — set your WinRM credentials

---

## Running Playbooks

```bash
# Test connectivity
ansible-playbook ping_test.yml

# Deploy Tailscale to all hosts
ansible-playbook deploy.yml

# Deploy to a specific group only
ansible-playbook deploy.yml --limit linux
ansible-playbook deploy.yml --limit windows
```

Because `vault_password_file` is set in `ansible.cfg`, you will not be
prompted for the vault password — it is read from `~/.vault_pass` automatically.

---

## Vault Reference

```bash
ansible-vault edit secrets.yml       # Edit (auto re-encrypts on save)
ansible-vault view secrets.yml       # View without editing
ansible-vault rekey secrets.yml      # Change the vault password
ansible-vault decrypt secrets.yml    # Decrypt to plaintext (do not commit after this)
ansible-vault encrypt secrets.yml    # Re-encrypt after manual edits
```

---

## File Structure

```
tailscale-ansible/
├── ansible.cfg                        # vault_password_file set here
├── deploy.yml                         # Main playbook
├── ping_test.yml                      # Connectivity test
├── inventory.ini                      # Host IPs split by [linux] / [windows]
├── secrets.yml                        # Vault-encrypted Tailscale auth key
├── .gitignore                         # Excludes .vault_pass
├── group_vars/
│   ├── linux.yml                      # SSH connection settings
│   └── windows.yml                    # WinRM connection settings
└── roles/
    ├── tailscale_linux/tasks/main.yml
    └── tailscale_windows/tasks/main.yml
```
