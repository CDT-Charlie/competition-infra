#!/bin/bash
# Generate and deploy MCP SSH keys — run from the ansible/ directory
ssh-keygen -t ed25519 -f ./ref_review_mcp_ed25519 -N ''
ansible-playbook -i inventory.yml deploy_greyteam_mcp_ssh.yml \
  -e ref_review_mcp_ssh_public_key_file="$PWD/ref_review_mcp_ed25519.pub" \
  -e ref_review_mcp_ssh_private_key_file="$PWD/ref_review_mcp_ed25519"
