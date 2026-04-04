# nix_mcp — Ref Review (read-only MCP server)

**Ref Review** is a single-file Python [Model Context Protocol](https://modelcontextprotocol.io) server for the Miracle on Ice competition. Blue Teams attach it to **Open WebUI** over **stdio**. It exposes one primary tool, **`analyze_linux_tampering`**, which SSHes as the domain principal configured in `ref_review_mcp.ssh_login` (default `greyteam@{{ ad_domain }}`, e.g. `greyteam@lakeplacid.local`) to other Blue Linux hosts in **10.100.2.0/24** (USA) or **10.100.3.0/24** (USSR) and returns a read-only, narrative “post-game recap” (systemd status, listening ports, NAT table snapshot, config paths, `/etc/hosts`).

This directory is the **Ansible role** `nix_mcp`. Deployment is driven from the main playbook ([`site.yml`](../../site.yml)); SSH key trust for MCP is a **separate** playbook ([`deploy_greyteam_mcp_ssh.yml`](../../deploy_greyteam_mcp_ssh.yml)).

---

## Prerequisites

### Infrastructure

| Requirement | Notes |
|---------------|--------|
| **Target hosts** | Inventory group **`mcp_hosts`**: `blue1-cross-check`, `blue2-cross-check` (see [`inventory.yml`](../../inventory.yml)). |
| **OS** | Ubuntu 20.04, 22.04, or 24.04. **20.04:** PyPI **`mcp`** needs **Python ≥3.10**; the role uses **[Astral uv](https://docs.astral.sh/uv/)** (pinned GitHub release tarball) plus [`files/uv-setup.sh`](files/uv-setup.sh) to install a **standalone CPython** and a venv under **`ref_review_mcp.install_dir`** — no deadsnakes / no system `python3.10` packages. **22.04+:** `python3` from apt and a normal `venv`. Targets need outbound HTTPS to **GitHub** (uv + Python builds) and **PyPI** unless you mirror. |
| **Active Directory / SSSD** | Domain user **`greyteam@lakeplacid.local`** (from `ad_domain` in [`group_vars/all.yml`](../../group_vars/all.yml)) must exist on cross-check and peers (typically after **`nix_base`** domain join). |
| **Peer Linux VMs** | Other scored Linux boxes (hat-trick, triple-deke, etc.) must be joined and reachable from cross-check over SSH. |
| **Network** | MCP only allows `target_ip` inside `REF_REVIEW_ALLOWED_SUBNETS` (see variables below). |

### On the Ansible controller

- **Ansible** 2.14+ recommended (uses `ansible.builtin.*` modules).
- **`ansible-playbook`** with SSH access to Linux targets as **`bootstrap_user`** (`cyberrange` by default) and **`become`** (sudo), per [`group_vars/blue_linux.yml`](../../group_vars/blue_linux.yml).
- For **`deploy_greyteam_mcp_ssh.yml`**: ability to **`lookup('file', ...)`** the public key path on the controller.

### For Open WebUI integration

- Open WebUI (or any MCP client) that can spawn a **stdio** server process.
- The OS user that **starts** the MCP process must be able to read:

  - The venv + scripts under **`ref_review_mcp.install_dir`** (owned by the domain principal after role completion), and  
  - The **private SSH key** at **`ref_review_mcp.ssh_identity_file`** (installed by `deploy_greyteam_mcp_ssh.yml` for `greyteam@realm`).

  In practice, run Open WebUI (or the wrapper) **as `greyteam@realm`** on the cross-check host, or align ownership and permissions with your site policy.

### Python on the target (installed by the role)

- **All:** `curl`, `ca-certificates`, `openssh-client`.
- **Ubuntu 20.04:** `uv` binary under **`{{ install_dir }}/uv/root`**, managed Python under **`{{ install_dir }}/uv/python`**, cache/data under **`uv/cache`** and **`uv/data`**. [`files/uv-setup.sh`](files/uv-setup.sh) runs **`uv python install`**, **`uv venv`**, **`uv pip install`** for **`ref_review_mcp.pip_packages`**.
- **22.04 / 24.04:** `python3`, `python3-venv`, `python3-pip`; venv via **`python3 -m venv`** and **`ansible.builtin.pip`**.
- If an old venv was built with Python &lt;3.10, the role **removes** it and rebuilds.
- PyPI package **`mcp`** (version constrained in variables, e.g. `mcp>=1.2.0`).

---

## Role layout

| Path | Purpose |
|------|---------|
| [`tasks/main.yml`](tasks/main.yml) | Installs deps, venv (uv on 20.04 / apt on 22.04+), deploys `ref_review_mcp.py`, env file, launcher script. |
| [`files/uv-setup.sh`](files/uv-setup.sh) | Ubuntu 20.04 only: `uv python install`, `uv venv`, `uv pip install` (env vars set by Ansible). |
| [`files/deploy.yml`](files/deploy.yml) | **Example only** — pattern “`script:` + `systemd`”; real deploy is this role via [`site.yml`](../../site.yml). |
| [`files/ref_review_mcp.py`](files/ref_review_mcp.py) | MCP server (FastMCP, stdio). |
| [`templates/ref_review_mcp.env.j2`](templates/ref_review_mcp.env.j2) | `/etc/default`-style env consumed by the launcher. |
| [`templates/run-ref-review-mcp.sh.j2`](templates/run-ref-review-mcp.sh.j2) | Sources env, `exec`s venv Python + `ref_review_mcp.py`. |
| [`defaults/main.yml`](defaults/main.yml) | Default `ref_review_mcp` dict (override in `group_vars`). |

---

## Variables

Primary definitions live in [`group_vars/linux.yml`](../../group_vars/linux.yml) under **`ref_review_mcp`**. [`defaults/main.yml`](defaults/main.yml) supplies the same keys with literals if group vars are not used.

| Key | Description |
|-----|-------------|
| `install_dir` | Install root (default `/opt/ref_review_mcp`). |
| `ssh_login` | SSH login passed to `ssh -l` (default `greyteam@{{ ad_domain }}`). |
| `ssh_home` | Home directory used when deploying the MCP private key (default `/home/greyteam@{{ ad_domain }}`). |
| `ssh_identity_file` | Private key path on cross-check; also **`REF_REVIEW_SSH_IDENTITY_FILE`** in env. |
| `ssh_connect_timeout` | SSH connect timeout (seconds). |
| `allowed_subnets` | Comma-joined into **`REF_REVIEW_ALLOWED_SUBNETS`**; targets outside these are rejected. |
| `poison_network` | CIDR(s) for “false signal” /etc/hosts checks (**`REF_REVIEW_POISON_CIDR`**). |
| `pip_packages` | **22.04+:** passed to `ansible.builtin.pip`. **20.04:** joined and passed to **`uv pip install`** by [`files/uv-setup.sh`](files/uv-setup.sh). |
| `uv_release` | Ubuntu 20.04: Astral **uv** version tag for the GitHub tarball (default `0.6.14`). Bump for fixes; must match a published **`uv-<triple>.tar.gz`**. |
| `uv_python` | Ubuntu 20.04: managed CPython version for **`uv python install`** / **`uv venv`** (default `3.10`). |
| `cleanup_legacy_focal_apt` | Ubuntu 20.04: remove **`ref-review-mcp-universe.list`** and **`*deadsnakes*`** files under **`/etc/apt/sources.list.d`** from older role/manual attempts (default true). |
| `file_owner` | Install tree owner: domain user (`greyteam@realm`). |
| `file_group` | Install tree group: domain user’s **primary group** from NSS (default `domain users@realm`), not the UPN—`chgrp` cannot use `greyteam@realm`. Override if `id greyteam@realm` shows a different group. |
| `env_file` | Path written by template (default `/etc/default/ref_review_mcp`). |

### Environment file → MCP behavior

| Variable (on disk) | Role |
|--------------------|------|
| `REF_REVIEW_SSH_USER` | Login name for `ssh -l` (must support `@` for realm logins). |
| `REF_REVIEW_SSH_IDENTITY_FILE` | If this path **exists**, SSH adds **`-i`** (needed for **BatchMode** with a dedicated key). |
| `REF_REVIEW_CONNECT_TIMEOUT` | Connect timeout. |
| `REF_REVIEW_ALLOWED_SUBNETS` | Comma-separated CIDRs. |
| `REF_REVIEW_POISON_CIDR` | Suspicious redirect range for `/etc/hosts` analysis. |

---

## Full setup (recommended order)

### 1. Join Linux hosts to AD

Run domain join so **`greyteam@realm`** exists on all Blue Linux systems (including **`mcp_hosts`** and service VMs):

```bash
cd ansible
ansible-playbook -i inventory.yml site.yml --tags domain_stack
```

(Or a full `site.yml` run that includes `nix_base` on `blue_linux` before services.)

### 2. Deploy scored services (optional but typical)

Includes **`nix_mcp`** on **`mcp_hosts`**:

```bash
ansible-playbook -i inventory.yml site.yml --tags services
```

Or deploy only Ref Review:

```bash
ansible-playbook -i inventory.yml site.yml --tags ref_review_mcp
```

The **`mcp_hosts`** play applies **`nix_base`** then **`nix_mcp`** ([`site.yml`](../../site.yml)).

### 3. Generate an MCP-dedicated SSH keypair (controller)

Do **not** commit private keys. On the Ansible controller:

```bash
ssh-keygen -t ed25519 -f ./ref_review_mcp_ed25519 -N ''
```

### 4. Distribute keys (public to all Blue Linux, private to cross-check only)

After AD join:

```bash
cd ansible
./scripts/deploy-greyteam-mcp-ssh.sh ./ref_review_mcp_ed25519.pub ./ref_review_mcp_ed25519
```

Equivalent:

```bash
ansible-playbook -i inventory.yml deploy_greyteam_mcp_ssh.yml \
  -e ref_review_mcp_ssh_public_key_file="$PWD/ref_review_mcp_ed25519.pub" \
  -e ref_review_mcp_ssh_private_key_file="$PWD/ref_review_mcp_ed25519"
```

This playbook:

1. Adds the **public** key to **`authorized_keys`** for **`ref_review_mcp.ssh_login`** on **`blue_linux`**.  
2. Copies the **private** key to **`ref_review_mcp.ssh_identity_file`** on **`mcp_hosts`** only.

### 5. Re-run or confirm `nix_mcp` if you changed variables

If you edited `ref_review_mcp` in `linux.yml`, re-run the Ref Review play so `/etc/default/ref_review_mcp` and the launcher stay in sync.

### 6. Configure Open WebUI (stdio MCP)

Point the client at the **launcher** (sources env, then runs Python):

- **Command:** `/opt/ref_review_mcp/run-ref-review-mcp.sh`  
  (or `bash` with that path as the argument, depending on the UI.)

- **Working directory:** optional; launcher uses absolute paths.

- **Transport:** stdio.

- **Run as:** a user that can read **`ssh_identity_file`** and the venv (normally **`greyteam@realm`** on cross-check).

---

## Tool: `analyze_linux_tampering`

**Arguments:**

- **`target_ip`** — IPv4/IPv6 of a peer Linux host (must fall inside allowed subnets).  
- **`service_name`** — systemd unit or alias (e.g. `nginx`, `mysqld`, `postfix`, `grafana-server`, `rsyslog`).

**Checks (read-only, over SSH):**

1. **Benchwarmer** — `systemctl is-active` / `is-enabled` (incl. masked).  
2. **Ghost Port** — `ss -tulpn` or `netstat`; compare to expected ports; `iptables -t nat -L -n` (with `sudo -n` fallback).  
3. **Shell Game** — default config files + `ls` for backup-style suffixes.  
4. **False Signal** — full `/etc/hosts` plus flags for addresses in poison CIDR(s).

No restart, write, or package changes on targets.

---

## Testing guide

### A. Preconditions

- `mcp_hosts` have completed **`nix_mcp`** (venv + `ref_review_mcp.py` + env + launcher).  
- **`deploy_greyteam_mcp_ssh.yml`** has run successfully.  
- From a cross-check host, the identity file exists and matches `ref_review_mcp.ssh_identity_file`:

  ```bash
  ls -l /home/greyteam@lakeplacid.local/.ssh/id_ref_review_mcp
  ```

  (Adjust realm if `ad_domain` differs.)

### B. Non-interactive SSH (BatchMode)

As the **same user** that will run the MCP server:

```bash
ssh -i /home/greyteam@lakeplacid.local/.ssh/id_ref_review_mcp \
  -l 'greyteam@lakeplacid.local' \
  -o BatchMode=yes \
  -o StrictHostKeyChecking=accept-new \
  10.100.3.4 \
  'systemctl is-active nginx || true'
```

- Use a **peer** IP in your USA/USSR range (e.g. hat-trick).  
- Exit code **0** with command output indicates key + login + `sshd` are aligned.  
- **Permission denied (publickey)** → public key missing on peer, wrong `authorized_keys` user, or wrong private key path.  
- **Connection timed out** → firewall / routing / wrong IP.

### C. Run the MCP server manually (stdio)

On cross-check, as the MCP runtime user:

```bash
set -a; source /etc/default/ref_review_mcp; set +a
/opt/ref_review_mcp/venv/bin/python /opt/ref_review_mcp/ref_review_mcp.py
```

Or:

```bash
/opt/ref_review_mcp/run-ref-review-mcp.sh
```

The process waits on stdin for MCP JSON-RPC. For a quick protocol check, use **[MCP Inspector](https://github.com/modelcontextprotocol/inspector)** (`npx @modelcontextprotocol/inspector`) and connect using your client’s documented stdio spawn command, or invoke a client that lists tools.

### D. Smoke test via MCP Inspector (optional)

1. Install/run MCP Inspector per upstream docs.  
2. Configure it to spawn:

   ` /opt/ref_review_mcp/run-ref-review-mcp.sh `

   on the cross-check host (SSH session or local console).  
3. Call **`analyze_linux_tampering`** with a valid **`target_ip`** and **`service_name`** (e.g. `nginx`).  
4. Confirm the returned text includes the four sections and “Coach, here is the tape…” style recap.

### E. Open WebUI

1. Add an MCP server entry with stdio command = **`/opt/ref_review_mcp/run-ref-review-mcp.sh`**.  
2. Ensure the process runs as a user with access to the private key and venv.  
3. In chat, invoke the tool with **`target_ip`** and **`service_name`**.  
4. If the model does not call tools automatically, use a prompt that explicitly asks for **`analyze_linux_tampering`**.

### F. Negative tests (optional)

- **Wrong subnet:** use an IP outside `10.100.2.0/24` and `10.100.3.0/24` — tool should refuse without SSH.  
- **Bad service name:** expect Benchwarmer / profile sections to reflect missing or unknown units.  
- **Missing identity file:** temporarily rename the private key; with **BatchMode**, SSH should fail unless another agent key applies.

---

## Troubleshooting

| Symptom | Things to check |
|---------|------------------|
| Ansible `authorized_key` / `getent` fails | Domain join incomplete; `ref_review_mcp.ssh_login` must match **`getent passwd`** on the host. |
| `chown` fails in `nix_mcp` | Domain user not resolvable yet; run after `nix_base` join. |
| MCP SSH always fails | `REF_REVIEW_SSH_IDENTITY_FILE` path wrong, file missing, or permissions; run section **B**. |
| `sudo` NAT table empty / unreadable | Peers may need passwordless sudo for `greyteam` to read `iptables -t nat -L -n`, or accept degraded NAT visibility (tool reports that). |
| Open WebUI shows no tools | stdio command wrong, crash on start (check venv `mcp` install), or wrong user. |
| **uv / Python download fails on 20.04** | Host must reach **GitHub** (`github.com`, `objects.githubusercontent.com` or your proxy allowlist). Check disk space under **`ref_review_mcp.install_dir`**. Bump **`uv_release`** if the tarball URL 404s. |
| **uv pip install / PyPI errors** | Outbound HTTPS to **PyPI**; proxy `HTTP(S)_PROXY` may need to be set for the root task environment if you add that later. |

---

## Related files

- [`../../site.yml`](../../site.yml) — `mcp_hosts` play (`nix_base`, `nix_mcp`).  
- [`../../deploy_greyteam_mcp_ssh.yml`](../../deploy_greyteam_mcp_ssh.yml) — MCP SSH key distribution.  
- [`../../scripts/deploy-greyteam-mcp-ssh.sh`](../../scripts/deploy-greyteam-mcp-ssh.sh) — Wrapper for that playbook.  
- [`../../group_vars/linux.yml`](../../group_vars/linux.yml) — `ref_review_mcp` overrides.
