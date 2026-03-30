#!/usr/bin/env bash
# Deploy your SSH public key to Linux VMs (default: blue_linux in inventory).
# Uses bootstrap_user from group_vars (cyberrange + password) for the initial SSH connection.
#
# Usage:
#   ./scripts/deploy-ssh-keys.sh
#   ./scripts/deploy-ssh-keys.sh /path/to/id_ed25519.pub
#   INVENTORY=../other-inventory.yml ./scripts/deploy-ssh-keys.sh
#   ./scripts/deploy-ssh-keys.sh -- --limit blue_team_1_linux
#
# Hosts with sshd AuthenticationMethods publickey,password (both required): use an identity that is
# already in authorized_keys on the target, then disable password-only forcing:
#   DEPLOY_SSH_FORCE_PASSWORD_ONLY=false ANSIBLE_SSH_PRIVATE_KEY_FILE=~/.ssh/image_bootstrap_key \
#     ./scripts/deploy-ssh-keys.sh ~/.ssh/id_ed25519.pub
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ANSIBLE_DIR"

INVENTORY="${INVENTORY:-inventory.yml}"
TARGET_GROUP="${TARGET_GROUP:-blue_linux}"

pick_key() {
  local k
  for k in \
    "${SSH_PUBLIC_KEY_FILE:-}" \
    "${HOME}/.ssh/id_ed25519.pub" \
    "${HOME}/.ssh/id_rsa.pub" \
    "${USERPROFILE:-}/.ssh/id_ed25519.pub" \
    "${USERPROFILE:-}/.ssh/id_rsa.pub"
  do
    [[ -n "$k" && -f "$k" ]] && { echo "$k"; return 0; }
  done
  return 1
}

EXTRA=()
if [[ "${1:-}" == *.pub && -f "${1:-}" ]]; then
  KEY="$1"
  shift
elif KEY="$(pick_key)"; then
  :
else
  echo "No public key found. Set SSH_PUBLIC_KEY_FILE or pass path to .pub file as first argument." >&2
  exit 1
fi

if [[ "${1:-}" == "--" ]]; then
  shift
fi

echo "Using public key: $KEY"
echo "Inventory: $INVENTORY  |  Host pattern group: $TARGET_GROUP"

EXTRA_VARS=(-e "ssh_public_key_file=$KEY" -e "target_group=$TARGET_GROUP")
if [[ "${DEPLOY_SSH_FORCE_PASSWORD_ONLY:-true}" == "false" ]]; then
  EXTRA_VARS+=(-e "deploy_ssh_force_password_only=false")
  echo "deploy_ssh_force_password_only=false (pubkey allowed for multi-method sshd)"
fi
if [[ -n "${ANSIBLE_SSH_PRIVATE_KEY_FILE:-}" ]]; then
  EXTRA_VARS+=(-e "ansible_ssh_private_key_file=${ANSIBLE_SSH_PRIVATE_KEY_FILE}")
  echo "ansible_ssh_private_key_file=${ANSIBLE_SSH_PRIVATE_KEY_FILE}"
fi

ansible-playbook \
  -i "$INVENTORY" \
  deploy_ssh_key.yml \
  "${EXTRA_VARS[@]}" \
  "$@"

echo
echo "Next runs can use key auth, for example:"
echo "  ansible-playbook -i $INVENTORY site.yml --private-key ~/.ssh/id_ed25519"
echo "  # or set in group_vars/blue_linux.yml: ansible_ssh_private_key_file: ~/.ssh/id_ed25519"
