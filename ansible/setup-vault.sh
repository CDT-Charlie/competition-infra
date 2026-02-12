#!/bin/bash
# Setup script for Ansible Vault
# This script helps create and manage the vault.yml file

set -e

VAULT_FILE="group_vars/vault.yml"
VAULT_EXAMPLE="group_vars/vault.yml.example"

echo "=========================================="
echo "Ansible Vault Setup"
echo "=========================================="
echo ""

# Check if vault file already exists
if [ -f "$VAULT_FILE" ]; then
    echo "⚠️  Vault file already exists: $VAULT_FILE"
    read -p "Do you want to recreate it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing vault file."
        exit 0
    fi
    rm "$VAULT_FILE"
fi

# Check if example file exists
if [ ! -f "$VAULT_EXAMPLE" ]; then
    echo "❌ Error: Example file not found: $VAULT_EXAMPLE"
    exit 1
fi

echo "Creating vault file from example..."
echo "You will be prompted to enter a vault password."
echo "Remember this password - you'll need it to run playbooks!"
echo ""

# Copy example and encrypt it
cp "$VAULT_EXAMPLE" "$VAULT_FILE"
ansible-vault encrypt "$VAULT_FILE"

echo ""
echo "✅ Vault file created successfully!"
echo ""
echo "Next steps:"
echo "1. Edit the vault file: ansible-vault edit $VAULT_FILE"
echo "2. Change all 'ChangeMe_*' passwords to secure values"
echo "3. Run playbooks with: ansible-playbook playbook.yml --ask-vault-pass"
echo ""
echo "Or use a password file:"
echo "  echo 'your-vault-password' > ~/.vault_pass"
echo "  chmod 600 ~/.vault_pass"
echo "  ansible-playbook playbook.yml --vault-password-file ~/.vault_pass"
