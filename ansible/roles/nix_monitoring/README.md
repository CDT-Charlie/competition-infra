# Grafana + rsyslog Monitoring Role

Deploys Grafana monitoring dashboard and rsyslog centralized logging.

## Features

### Grafana
- Installs Grafana from official repository
- Configures HTTP port, domain, and admin credentials
- Enables and starts Grafana service

### rsyslog
- Server mode: Receives logs from clients, stores in organized directory structure
- Client mode: Forwards logs to central server
- Log rotation and compression
- Noise filtering (optional)

## Requirements

- Debian/Ubuntu Linux
- Ansible 2.9+
- Root or sudo access

## Role Variables

All variables use centralized `group_vars/all.yml` by default. See `defaults/main.yml` for role-specific defaults.

### Grafana Variables

- `grafana.enabled`: Enable Grafana (default: true)
- `grafana.admin_user`: Admin username
- `grafana.admin_password`: Admin password (from vault)
- `grafana.http_port`: HTTP port (default: 3000)
- `grafana.domain`: Domain name

### rsyslog Variables

- `rsyslog.enabled`: Enable rsyslog (default: true)
- `rsyslog.mode`: "server" or "client"
- `rsyslog.remote_log_dir`: Directory for remote logs (server mode)
- `rsyslog.tcp_port`: TCP port for log forwarding
- `syslog_server`: Central server hostname/IP (client mode)

## Dependencies

None

## Example Playbook

```yaml
# Server mode
- name: Deploy Monitoring Server
  hosts: monitoring_server
  become: yes
  vars:
    rsyslog:
      mode: "server"
  roles:
    - nix_monitoring

# Client mode
- name: Deploy Monitoring Client
  hosts: monitoring_clients
  become: yes
  vars:
    grafana:
      enabled: false
    rsyslog:
      mode: "client"
    syslog_server: "monitoring_server.example.com"
  roles:
    - nix_monitoring
```

## Notes

- Grafana and rsyslog can be enabled/disabled independently
- rsyslog server mode includes log rotation
- Client mode requires `syslog_server` variable to be set
