#!/bin/bash
# Ref Review — uv-managed Python + venv under REF_REVIEW_INSTALL_DIR (Ubuntu 20.04 / Focal).
# Invoked by Ansible (become root). Paths and packages come from the environment; no systemd here (stdio MCP).
set -euo pipefail

INSTALL_DIR="${REF_REVIEW_INSTALL_DIR:?set REF_REVIEW_INSTALL_DIR}"
UV_ROOT="${REF_REVIEW_UV_ROOT:?set REF_REVIEW_UV_ROOT}"
UV_PYTHON="${REF_REVIEW_UV_PYTHON:-3.10}"
PIP_PACKAGES="${REF_REVIEW_PIP_PACKAGES:-}"

export UV_PYTHON_INSTALL_DIR="${UV_PYTHON_INSTALL_DIR:?set UV_PYTHON_INSTALL_DIR}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:?set XDG_CACHE_HOME}"
export XDG_DATA_HOME="${XDG_DATA_HOME:?set XDG_DATA_HOME}"
export PATH="${UV_ROOT}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

UV_BIN="${UV_ROOT}/uv"
if [[ ! -x "${UV_BIN}" ]]; then
  echo "uv-setup.sh: missing or non-executable ${UV_BIN}" >&2
  exit 1
fi

echo "uv-setup.sh: uv-managed Python ${UV_PYTHON} under ${INSTALL_DIR}..."
"${UV_BIN}" python install "${UV_PYTHON}"
if [[ ! -x "${INSTALL_DIR}/venv/bin/python" ]]; then
  "${UV_BIN}" venv "${INSTALL_DIR}/venv" --python "${UV_PYTHON}"
fi

if [[ -n "${PIP_PACKAGES}" ]]; then
  # shellcheck disable=SC2086
  "${UV_BIN}" pip install --python "${INSTALL_DIR}/venv/bin/python" ${PIP_PACKAGES}
fi

"${INSTALL_DIR}/venv/bin/python" -c 'import sys; assert sys.version_info >= (3, 10), sys.version'
echo "uv-setup.sh: done."
