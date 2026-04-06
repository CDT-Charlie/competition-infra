#!/usr/bin/env bash
# Deploy Ref Review MCP SSH keypair: public key → greyteam@realm on all blue_linux;
# private key → mcp_hosts only. Run after AD join (site.yml domain_stack).
#
# Usage:
#   ./scripts/deploy-greyteam-mcp-ssh.sh /path/to/ref_review_mcp_ed25519.pub /path/to/ref_review_mcp_ed25519
#   INVENTORY=../other-inventory.yml ./scripts/deploy-greyteam-mcp-ssh.sh key.pub key
#   ./scripts/deploy-greyteam-mcp-ssh.sh key.pub key -- --limit blue_team_1_linux
#
# Generate keys (controller, once):
#   ssh-keygen -t ed25519 -f ./ref_review_mcp_ed25519 -N ''
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ANSIBLE_DIR"

INVENTORY="${INVENTORY:-inventory.yml}"

if [[ "${1:-}" == *.pub && -f "${1:-}" && -n "${2:-}" && -f "${2:-}" ]]; then
  PUB="$1"
  PRIV="$2"
  shift 2
elif [[ -n "${REF_REVIEW_MCP_SSH_PUBLIC_KEY_FILE:-}" && -n "${REF_REVIEW_MCP_SSH_PRIVATE_KEY_FILE:-}" ]]; then
  PUB="${REF_REVIEW_MCP_SSH_PUBLIC_KEY_FILE}"
  PRIV="${REF_REVIEW_MCP_SSH_PRIVATE_KEY_FILE}"
else
  echo "Usage: $0 <path-to-public.pub> <path-to-private-key>" >&2
  echo "Or set REF_REVIEW_MCP_SSH_PUBLIC_KEY_FILE and REF_REVIEW_MCP_SSH_PRIVATE_KEY_FILE." >&2
  exit 1
fi

if [[ "${1:-}" == "--" ]]; then
  shift
fi

echo "Public key:  $PUB"
echo "Private key: $PRIV"
echo "Inventory:   $INVENTORY"

ansible-playbook \
  -i "$INVENTORY" \
  deploy_greyteam_mcp_ssh.yml \
  -e "ref_review_mcp_ssh_public_key_file=$PUB" \
  -e "ref_review_mcp_ssh_private_key_file=$PRIV" \
  "$@"

echo
echo "Verify on a cross-check host (as the user that runs Open WebUI / MCP):"
echo "  ssh -i <identity-from-env> -l 'greyteam@lakeplacid.local' -o BatchMode=yes <peer-ip> true"
