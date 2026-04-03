#!/bin/bash

# SSH public key to push
PUB_KEY_PATH="${1:-$HOME/.ssh/id_ed25519.pub}"

# Linux host IPs from inventory
LINUX_HOSTS=(
    "10.100.2.3"
    "10.100.2.4"
    "10.100.2.5"
    "10.100.2.6"
    "10.100.2.7"
    "10.100.2.8"
    "10.100.3.3"
    "10.100.3.4"
    "10.100.3.5"
    "10.100.3.6"
    "10.100.3.7"
    "10.100.3.8"
)

# SSH user to log in as
SSH_USER="cyberrange"

# -------------------------------------------

if [ ! -f "$PUB_KEY_PATH" ]; then
    echo "ERROR: Public key not found at $PUB_KEY_PATH"
    echo "Usage: ./push_ssh_key.sh [/path/to/key.pub]"
    exit 1
fi

echo "Pushing $PUB_KEY_PATH to all Linux hosts as user '$SSH_USER'..."
echo "You will be prompted for a password for each host."
echo "-------------------------------------------"

SUCCESS=()
FAILED=()

for HOST in "${LINUX_HOSTS[@]}"; do
    echo ""
    echo ">>> $HOST"
    ssh-copy-id -i "$PUB_KEY_PATH" "$SSH_USER@$HOST"
    if [ $? -eq 0 ]; then
        SUCCESS+=("$HOST")
    else
        FAILED+=("$HOST")
    fi
done

echo ""
echo "==========================================="
echo "RESULTS"
echo "==========================================="
echo "Succeeded (${#SUCCESS[@]}):"
for H in "${SUCCESS[@]}"; do echo "  ✓ $H"; done

if [ ${#FAILED[@]} -gt 0 ]; then
    echo ""
    echo "Failed (${#FAILED[@]}):"
    for H in "${FAILED[@]}"; do echo "  ✗ $H"; done
    exit 1
fi
