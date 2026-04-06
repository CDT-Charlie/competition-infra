#!/bin/bash
# Enable root SSH login for the scoring engine
# Replaces #PermitRootLogin prohibit-password or PermitRootLogin no with yes

sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

# Reload the SSH service to apply changes safely (avoiding active connection drops)
systemctl reload ssh
