#!/usr/bin/env python3
"""
Ref Review — read-only MCP server for Miracle on Ice / Grey Team.
Uses SSH (BatchMode, domain principal via -l) to run read-only commands on Blue Team Linux hosts.
Transport: stdio (Open WebUI friendly). Official SDK: mcp.server.fastmcp.FastMCP.
"""

from __future__ import annotations

import ipaddress
import os
import re
import shlex
import subprocess
from dataclasses import dataclass, field
from typing import Iterable, Union

from mcp.server.fastmcp import FastMCP

# ---------------------------------------------------------------------------
# Configuration (override via environment — Ansible can template /etc/default/ref_review_mcp)
# ---------------------------------------------------------------------------

ENV_SSH_USER = "REF_REVIEW_SSH_USER"
ENV_SSH_IDENTITY_FILE = "REF_REVIEW_SSH_IDENTITY_FILE"
ENV_CONNECT_TIMEOUT = "REF_REVIEW_CONNECT_TIMEOUT"
ENV_ALLOWED_SUBNETS = "REF_REVIEW_ALLOWED_SUBNETS"
ENV_POISON_CIDR = "REF_REVIEW_POISON_CIDR"


def _env_int(name: str, default: int) -> int:
    raw = os.environ.get(name)
    if raw is None or raw.strip() == "":
        return default
    try:
        return int(raw)
    except ValueError:
        return default


Net = Union[ipaddress.IPv4Network, ipaddress.IPv6Network]


def _load_allowed_subnets() -> list[Net]:
    raw = os.environ.get(ENV_ALLOWED_SUBNETS, "10.100.2.0/24,10.100.3.0/24")
    nets: list[Net] = []
    for part in raw.split(","):
        part = part.strip()
        if not part:
            continue
        try:
            nets.append(ipaddress.ip_network(part, strict=False))
        except ValueError:
            continue
    return nets


def _load_poison_networks() -> list[Net]:
    """Flag lines in /etc/hosts that point into Red Team-ish space (default 10.100.1.0/24)."""
    raw = os.environ.get(ENV_POISON_CIDR, "10.100.1.0/24")
    nets: list[Net] = []
    for part in raw.split(","):
        part = part.strip()
        if not part:
            continue
        try:
            nets.append(ipaddress.ip_network(part, strict=False))
        except ValueError:
            continue
    if not nets:
        nets.append(ipaddress.ip_network("10.100.1.0/24", strict=False))
    return nets


def _ssh_user() -> str:
    return os.environ.get(ENV_SSH_USER, "greyteam").strip() or "greyteam"


def _ssh_identity_path() -> str | None:
    """Optional private key path for BatchMode (must exist on disk to be used)."""
    p = os.environ.get(ENV_SSH_IDENTITY_FILE, "").strip()
    if p and os.path.isfile(p):
        return p
    return None


def _connect_timeout() -> int:
    return max(3, min(120, _env_int(ENV_CONNECT_TIMEOUT, 15)))


def validate_target_ip(addr: str, allowed: Iterable[Net]) -> Union[ipaddress.IPv4Address, ipaddress.IPv6Address]:
    """Ensure target is a single host IP and (if configured) inside allowed competition subnets."""
    try:
        ip = ipaddress.ip_address(addr.strip())
    except ValueError as e:
        raise ValueError(f"Invalid target_ip: {addr!r} ({e})") from e
    allowed_list = list(allowed)
    if allowed_list:
        ok = any(ip in net for net in allowed_list)
        if not ok:
            raise ValueError(
                f"target_ip {addr} is outside allowed subnets "
                f"({', '.join(str(n) for n in allowed_list)}). "
                "Refuse to SSH outside the USA/USSR ranges."
            )
    return ip


def normalize_service_key(service_name: str) -> str:
    s = service_name.strip().lower()
    if s.endswith(".service"):
        s = s[: -len(".service")]
    return s


@dataclass
class ServiceProfile:
    """Maps a logical service / unit to ports, process hints, and config paths."""

    display_name: str
    ports: list[int]
    process_substrings: list[str]
    config_files: list[str]
    config_dirs: list[str]
    aliases: list[str] = field(default_factory=list)


# Competition-oriented catalog (Miracle on Ice scored services).
_profiles: list[ServiceProfile] = [
    ServiceProfile(
        display_name="Nginx",
        ports=[80, 443],
        process_substrings=["nginx"],
        config_files=["/etc/nginx/nginx.conf"],
        config_dirs=["/etc/nginx"],
        aliases=["nginx", "nginx.service"],
    ),
    ServiceProfile(
        display_name="MySQL / MariaDB",
        ports=[3306],
        process_substrings=["mysqld", "mariadbd", "mysql"],
        config_files=["/etc/mysql/my.cnf", "/etc/mysql/mysql.conf.d/mysqld.cnf"],
        config_dirs=["/etc/mysql"],
        aliases=["mysql", "mysqld", "mariadb", "mariadb.service", "mysql.service"],
    ),
    ServiceProfile(
        display_name="Postfix (SMTP)",
        ports=[25],
        process_substrings=["master", "postfix"],  # master is postfix master on many distros
        config_files=["/etc/postfix/main.cf"],
        config_dirs=["/etc/postfix"],
        aliases=["postfix", "postfix.service"],
    ),
    ServiceProfile(
        display_name="Dovecot (IMAP/POP)",
        ports=[143, 993, 110, 995],
        process_substrings=["dovecot"],
        config_files=["/etc/dovecot/dovecot.conf"],
        config_dirs=["/etc/dovecot"],
        aliases=["dovecot", "dovecot.service"],
    ),
    ServiceProfile(
        display_name="Grafana",
        ports=[3000],
        process_substrings=["grafana"],
        config_files=["/etc/grafana/grafana.ini"],
        config_dirs=["/etc/grafana"],
        aliases=["grafana-server", "grafana", "grafana.service"],
    ),
    ServiceProfile(
        display_name="Rsyslog",
        ports=[514],
        process_substrings=["rsyslogd", "rsyslog"],
        config_files=["/etc/rsyslog.conf"],
        config_dirs=["/etc/rsyslog.d"],
        aliases=["rsyslog", "rsyslog.service"],
    ),
    ServiceProfile(
        display_name="MCP / Cross-check (stdio-style daemon)",
        ports=[],  # often no TCP listener; Benchwarmer + files still matter
        process_substrings=["python", "uvicorn", "node", "mcp"],
        config_files=[],
        config_dirs=["/etc/systemd/system"],
        aliases=["ref-review", "ref_review", "mcp", "cross-check"],
    ),
]

SERVICE_CATALOG: dict[str, ServiceProfile] = {}


def _register_profile(p: ServiceProfile) -> None:
    for alias in p.aliases:
        SERVICE_CATALOG[normalize_service_key(alias)] = p


for _p in _profiles:
    _register_profile(_p)


def resolve_profile(service_name: str) -> ServiceProfile | None:
    key = normalize_service_key(service_name)
    if key in SERVICE_CATALOG:
        return SERVICE_CATALOG[key]
    for prof in _profiles:
        if key in {normalize_service_key(a) for a in prof.aliases}:
            return prof
    return None


def ssh_exec(
    target_ip: str,
    remote_bash: str,
    timeout: int | None = None,
) -> tuple[int, str, str]:
    """
    Run a read-only remote command via SSH. No shell injection on local side:
    remote_bash is passed as a single argument to ssh (remote executes with user login shell).
    """
    t = timeout if timeout is not None else _connect_timeout() + 25
    user = _ssh_user()
    ssh_opts = [
        "-o",
        "BatchMode=yes",
        "-o",
        f"ConnectTimeout={_connect_timeout()}",
        "-o",
        "StrictHostKeyChecking=accept-new",
    ]
    # Domain logins (e.g. greyteam@lakeplacid.local) must use -l, not user@host (ambiguous @).
    cmd: list[str] = ["ssh", *ssh_opts]
    ident = _ssh_identity_path()
    if ident:
        cmd.extend(["-i", ident])
    cmd.extend(["-l", user, target_ip, remote_bash])
    try:
        proc = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=t,
            check=False,
        )
        return proc.returncode, proc.stdout or "", proc.stderr or ""
    except subprocess.TimeoutExpired:
        return 124, "", f"SSH command timed out after {t}s"
    except FileNotFoundError:
        return 127, "", "ssh executable not found on PATH"
    except OSError as e:
        return 1, "", f"SSH failed to start: {e}"


def _summarize_systemctl(is_active_out: str, is_enabled_out: str, rc_active: int, rc_enabled: int) -> list[str]:
    lines: list[str] = []
    active = (is_active_out or "").strip()
    enabled = (is_enabled_out or "").strip()
    lines.append(f"  is-active (exit {rc_active}): {active or '(no stdout)'}")
    lines.append(f"  is-enabled (exit {rc_enabled}): {enabled or '(no stdout)'}")

    if enabled.lower() == "masked":
        lines.append("  ** Whistle: unit is MASKED — it cannot start until unmasked.")
    if active.lower() in ("inactive", "failed", "dead"):
        lines.append("  ** Benchwarmer alert: service does not report active.")
    if active.lower() == "failed":
        lines.append("  ** Service is in failed state — check journal on host.")
    if rc_active != 0 and active.lower() not in ("active", "activating", "reloading"):
        lines.append("  ** Non-zero is-active — worth a closer look at the tape.")
    return lines


def _parse_ss_for_ports(ss_out: str, want_ports: list[int], hints: list[str]) -> list[str]:
    """Lightweight parse of `ss -tulpn` / netstat lines for LISTEN + port + process hint."""
    findings: list[str] = []
    if not ss_out.strip():
        return ["  (no socket listing output — tool missing or permission denied?)"]
    for port in want_ports:
        # Match ":80", ":3306", etc. (TCP LISTEN and UDP unbound sockets both show a port segment).
        needle = f":{port}"
        hits = [ln for ln in ss_out.splitlines() if needle in ln and not ln.strip().startswith("#")]
        if not hits:
            findings.append(f"  Port {port}/tcp (or udp): no obvious LISTEN line in ss/netstat output.")
            continue
        for ln in hits[:5]:
            hint_ok = any(h in ln.lower() for h in hints) if hints else True
            flag = "OK" if hint_ok else "CHECK"
            findings.append(f"  [{flag}] {ln.strip()}")
    return findings


def _hosts_poison_scan(hosts_content: str, poison_nets: list[Net]) -> list[str]:
    lines_out: list[str] = []
    if not hosts_content.strip():
        lines_out.append("  /etc/hosts empty or unreadable.")
        return lines_out

    ip_re = re.compile(
        r"^(\s*)(\d{1,3}(?:\.\d{1,3}){3})\s+(\S.*)$"
    )
    suspicious: list[str] = []
    for raw in hosts_content.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        m = ip_re.match(line)
        if not m:
            continue
        ip_s = m.group(2)
        try:
            ip = ipaddress.ip_address(ip_s)
        except ValueError:
            continue
        if any(ip in net for net in poison_nets):
            suspicious.append(line)

    if suspicious:
        lines_out.append("  ** False Signal: entries route names into the suspicious range:")
        for s in suspicious[:20]:
            lines_out.append(f"    - {s}")
        if len(suspicious) > 20:
            lines_out.append(f"    ... and {len(suspicious) - 20} more")
    else:
        lines_out.append("  No IPv4 /etc/hosts entries found in the flagged poison CIDRs.")
    return lines_out


def _shell_game_section(profile: ServiceProfile | None, service_name: str, target_ip: str) -> list[str]:
    lines: list[str] = ["**3. The Shell Game (file integrity & layout)**"]
    if profile is None:
        lines.append(
            f"  No built-in config map for `{service_name}` — skipping default paths; "
            "try a well-known unit name (nginx, mysqld, postfix, grafana-server, rsyslog)."
        )
        return lines

    for path in profile.config_files:
        quoted = shlex.quote(path)
        rc, out, err = ssh_exec(target_ip, f"if test -f {quoted}; then echo EXISTS; else echo MISSING; fi")
        msg = (out + err).strip()
        lines.append(f"  {path}: {msg} (exit {rc})")

    seen_dirs: set[str] = set()
    for d in profile.config_dirs:
        if d in seen_dirs or d.endswith(".conf"):
            continue
        seen_dirs.add(d)
        quoted = shlex.quote(d)
        rc, out, err = ssh_exec(
            target_ip,
            f"if test -d {quoted}; then ls -la {quoted}; else echo 'DIR_MISSING'; fi",
        )
        body = (out or err or "").strip()
        preview = "\n".join(body.splitlines()[:40])
        backup_hits = [ln for ln in body.splitlines() if re.search(r"\.(bak|old|orig|save|dpkg-dist)\b", ln, re.I)]
        lines.append(f"  Directory listing: {d} (exit {rc})")
        lines.append("    " + preview.replace("\n", "\n    "))
        if backup_hits:
            lines.append("  ** Spotted alternate/backup-style filenames — verify intentional changes.")
    return lines


def analyze_linux_tampering_impl(target_ip: str, service_name: str) -> str:
    """Core analysis used by the MCP tool."""
    allowed = _load_allowed_subnets()
    poison = _load_poison_networks()

    try:
        validate_target_ip(target_ip, allowed)
    except ValueError as e:
        return f"Coach, we could not drop the puck — {e}"

    svc = service_name.strip()
    if not svc:
        return "Coach, I need a service_name on the jersey — that argument was empty."

    profile = resolve_profile(svc)
    display = profile.display_name if profile else service_name
    key = normalize_service_key(svc)

    recap: list[str] = [
        f"Coach, here is the tape on **{display}** at `{target_ip}` (unit key `{key}`).",
        "",
        "**1. The Benchwarmer Check (systemd)**",
    ]

    unit = shlex.quote(svc)
    rc_a, out_a, err_a = ssh_exec(target_ip, f"systemctl is-active {unit}")
    rc_e, out_e, err_e = ssh_exec(target_ip, f"systemctl is-enabled {unit}")
    if (err_a + err_e).strip():
        recap.append(f"  (ssh stderr) {(err_a + err_e).strip()}")
    recap.extend(_summarize_systemctl(out_a, out_e, rc_a, rc_e))

    # Ghost Port
    recap.append("")
    recap.append("**2. The Ghost Port Check (listeners + NAT)**")
    if profile and profile.ports:
        rc_ss, out_ss, err_ss = ssh_exec(
            target_ip,
            "command -v ss >/dev/null 2>&1 && ss -tulpn || netstat -tulpn 2>/dev/null || echo NO_SOCKET_TOOL",
        )
        if err_ss.strip():
            recap.append(f"  ss/netstat stderr: {err_ss.strip()}")
        recap.extend(_parse_ss_for_ports(out_ss, profile.ports, profile.process_substrings))
    elif profile:
        recap.append(
            f"  Profile `{display}` has no default TCP/UDP port list (e.g. stdio MCP). "
            "Skipping port binding check; still review NAT below."
        )
    else:
        recap.append("  Unknown service profile — run ss/netstat snapshot for manual review:")
        rc_ss, out_ss, _ = ssh_exec(
            target_ip,
            "command -v ss >/dev/null 2>&1 && ss -tulpn | head -n 80 || netstat -tulpn 2>/dev/null | head -n 80",
        )
        recap.append("    " + (out_ss.strip() or "(empty)").replace("\n", "\n    "))

    # NAT / PREROUTING — read-only; try non-interactive sudo first
    rc_nat, out_nat, err_nat = ssh_exec(
        target_ip,
        "sudo -n iptables -t nat -L -n 2>/dev/null || iptables -t nat -L -n 2>/dev/null || echo NAT_UNREADABLE",
    )
    nat_blob = (out_nat + err_nat).strip()
    recap.append("  iptables NAT table (filter for unexpected DNAT/REDIRECT):")
    recap.append("    " + nat_blob.replace("\n", "\n    "))
    if "NAT_UNREADABLE" in nat_blob or not nat_blob:
        recap.append(
            "  ** Could not read NAT rules (may need passwordless sudo for greyteam). "
            "Redirection tampering might still exist."
        )

    # Shell Game
    recap.append("")
    recap.extend(_shell_game_section(profile, svc, target_ip))

    # False Signal
    recap.append("")
    recap.append("**4. The False Signal Check (/etc/hosts poisoning)**")
    rc_h, out_h, err_h = ssh_exec(target_ip, "cat /etc/hosts 2>/dev/null")
    hosts_body = out_h if rc_h == 0 else ""
    if err_h.strip():
        recap.append(f"  stderr: {err_h.strip()}")
    recap.append("  Raw /etc/hosts:")
    recap.append("    " + (hosts_body.strip() or "(unreadable)").replace("\n", "\n    "))
    recap.extend(_hosts_poison_scan(hosts_body, poison))

    recap.append("")
    recap.append(
        "--- End of shift. All checks were read-only (no restarts, no writes). "
        "Verify anything flagged with local journals and change control. ---"
    )
    return "\n".join(recap)


# ---------------------------------------------------------------------------
# MCP server (stdio)
# ---------------------------------------------------------------------------

mcp = FastMCP(
    "Ref Review",
    instructions=(
        "Grey Team read-only inspector: SSH with -l domain principal (e.g. greyteam@realm) to Blue Linux hosts "
        "in 10.100.2.0/24 (USA) or 10.100.3.0/24 (USSR) and report systemd, ports, "
        "configs, NAT, and /etc/hosts tampering in a narrative recap."
    ),
)


@mcp.tool()
def analyze_linux_tampering(target_ip: str, service_name: str) -> str:
    """
    SSH to target_ip and run read-only checks: systemd active/enabled (incl. masked),
    listening ports vs expected service, iptables NAT table, config paths + directory
    listings, and /etc/hosts for redirects into the Red Team range.

    Args:
        target_ip: IPv4/IPv6 address of the Blue Team Linux host (must be in allowed subnets).
        service_name: systemd unit name or alias (e.g. nginx, mysqld, postfix, grafana-server, rsyslog).
    """
    return analyze_linux_tampering_impl(target_ip, service_name)


def main() -> None:
    # Default transport for FastMCP direct execution is stdio — ideal for Open WebUI.
    mcp.run()


if __name__ == "__main__":
    main()
