#!/bin/bash
# Ubuntu 20.04 only: install Python 3.10 + venv via deadsnakes PPA (non-interactive).
# Mirrors the usual manual steps; safe to re-run (apt installs are idempotent).
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

if [[ ! -r /etc/os-release ]]; then
  echo "install_python310_focal.sh: /etc/os-release not found" >&2
  exit 1
fi
# shellcheck source=/dev/null
. /etc/os-release
if [[ "${VERSION_CODENAME:-}" != "focal" ]]; then
  echo "install_python310_focal.sh: skipping (not focal, codename=${VERSION_CODENAME:-unknown})"
  exit 0
fi

echo "install_python310_focal.sh: configuring apt for Python 3.10 (Focal)..."

apt-get update -qq
apt-get install -y software-properties-common

# Helpful on minimal images; deadsnakes remains the source of python3.10.
add-apt-repository -y universe || true

add-apt-repository -y ppa:deadsnakes/ppa

# Some clouds/proxies break http://ppa.launchpad.net indexes; HTTPS content host is preferred.
shopt -s nullglob
for f in /etc/apt/sources.list.d/deadsnakes*.list; do
  sed -i 's|http://ppa.launchpad.net/|https://ppa.launchpadcontent.net/|g' "$f"
done
shopt -u nullglob

apt-get update -qq

# distutils helps pip/bootstrap edge cases on older stacks; venv is required for Ref Review venv.
apt-get install -y python3.10 python3.10-venv python3.10-distutils

python3.10 --version
echo "install_python310_focal.sh: done."
