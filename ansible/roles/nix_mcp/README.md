# nix_mcp — Ref Review MCP (Grey Team)

Ansible role that deploys the **Ref Review** MCP server, **Gemini CLI**, and supporting infrastructure on `mcp_hosts` (cross-check Linux boxes).

## What it deploys

| Component | Location |
|-----------|----------|
| MCP server script | `/opt/ref_review_mcp/ref_review_mcp.py` |
| Python venv (with `mcp` SDK) | `/opt/ref_review_mcp/venv/` |
| Stdio launcher | `/opt/ref_review_mcp/run-ref-review-mcp.sh` |
| Environment file | `/etc/default/ref_review_mcp` |
| Gemini CLI | `/usr/bin/gemini` (npm global) |
| Gemini settings (MCP auto-connect) | `~/.gemini/settings.json` (all users) |
| Gemini API key | `~/.gemini/.env` + `/etc/profile.d/gemini-api-key.sh` (all users) |
| Systemd service (tmux daemon) | `ref-review.service` |
| Root SSH access for scoring | `allow_root_ssh.sh` (sets root password, enables PermitRootLogin) |

---

## Grey Team MCP Deploy — From Scratch

```bash
# 1. Clone the repo
git clone https://github.com/CDT-Charlie/competition-infra.git
cd competition-infra/ansible

# 2. Run the main site playbook (deploys everything including nix_mcp role)
#    Pass your Gemini API key at runtime (API is tied to greyteam.cdt.charlie gmail account)
ansible-playbook -i inventory.yml site.yml -e gemini_api_key_input="YOUR_GEMINI_API_KEY"

# 3. Generate and distribute MCP SSH keys
bash mcp-keys.sh

# 4. Verify (optional — from deploy box)
ssh root@10.100.2.3 systemctl is-active ref-review
```

> **NOTE:** If the SSH keys change on the scoring box, you will need to run:
> `ssh-copy-id root@10.100.2.3 && ssh-copy-id root@10.100.3.3`

---

## Using Gemini CLI on the MCP Box

1. **SSH into the MCP box** and open the Gemini CLI:
   ```bash
   gemini
   ```
2. **Verify MCP is connected:**
   ```
   /mcp list
   ```
   You should see `ref-review-server - Ready (1 tool)`.

3. **Ask the AI to inspect a host:**
   ```
   Use the ref-review-server to analyze nginx on 10.100.2.4
   ```

4. **Attach to the running daemon** (if using the systemd tmux session):
   ```bash
   tmux attach -t gemini
   ```
   Detach safely with `Ctrl+B`, then `D`. Do **not** type `exit` or systemd will restart the session.

---

## MCP Tool: `analyze_linux_tampering`

SSHes to a Blue Team Linux host and runs **read-only** checks:

| Check | What it does |
|-------|-------------|
| Benchwarmer | `systemctl is-active` / `is-enabled` (catches stopped, failed, masked) |
| Ghost Port | `ss -tulpn` for expected ports + `iptables -t nat -L -n` for NAT redirects |
| Shell Game | Config file existence + directory listings for backup-style tampering |
| False Signal | `/etc/hosts` scan for IPs in the poison CIDR (Red Team range) |

**Arguments:** `target_ip` (must be in 10.100.2.0/24 or 10.100.3.0/24), `service_name` (e.g. `nginx`, `mysqld`, `postfix`, `grafana-server`, `rsyslog`)

---

## Scoring (Red vs Blue)

The scoring engine runs a simplified check against MCP boxes every few seconds.

**What is checked:**
1. `systemctl is-active ref-review` — is the service running?
2. `test -f /opt/ref_review_mcp/ref_review_mcp.py` — does the script exist?

**True** = both pass. **False** = either failed.

**To restore a failed score:**
```bash
sudo systemctl restart ref-review
ls /opt/ref_review_mcp/ref_review_mcp.py  # if missing, rerun ansible
```

---

## Variables

Defined in `group_vars/linux.yml` under `ref_review_mcp`:

| Key | Description |
|-----|-------------|
| `install_dir` | Install root (default `/opt/ref_review_mcp`) |
| `ssh_login` | SSH login for MCP tool (`greyteam@{{ ad_domain }}`) |
| `ssh_home` | Home directory for greyteam domain user |
| `pip_packages` | Python packages installed in venv (e.g. `mcp>=1.2.0`) |
| `file_owner` / `file_group` | Ownership for deployed files |
| `gemini_api_key` | Injected at runtime via `-e gemini_api_key_input="..."` |

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Gemini CLI says "No MCP servers configured" | Check `~/.gemini/settings.json` exists with `mcpServers` block |
| API key error / "reported as leaked" | Generate a new key, redeploy with `-e gemini_api_key_input="NEW_KEY"` |
| Score check returns False | `sudo systemctl restart ref-review` on the MCP box |
| SSH key deploy fails with "No such file or directory" | Home directory doesn't exist yet — rerun `site.yml` to ensure domain join first |
| MCP tool SSH fails | Run `bash mcp-keys.sh` on deploy box to distribute keys |

---

## Related Files

- [`site.yml`](../../site.yml) — main playbook (`mcp_hosts` play)
- [`deploy_greyteam_mcp_ssh.yml`](../../deploy_greyteam_mcp_ssh.yml) — MCP SSH key distribution
- [`mcp-keys.sh`](../../mcp-keys.sh) — one-shot key generation + distribution script
- [`group_vars/linux.yml`](../../group_vars/linux.yml) — `ref_review_mcp` variable overrides
