# Postfix + Dovecot Mail Server Role

Deploys a complete mail server with Postfix (SMTP) and Dovecot (IMAP/POP3).

## Features

- Installs Dovecot 2.4 (IMAP/POP3 server)
- Installs Postfix (SMTP server)
- Creates SSL/TLS certificates
- Configures service accounts (vmail)
- Configures mail delivery and storage

## Requirements

- Debian/Ubuntu Linux
- Ansible 2.9+
- Root or sudo access

## Role Variables

All variables use centralized `group_vars/all.yml` by default. See `defaults/main.yml` for role-specific defaults.

### Key Variables

- `ssl.*`: SSL certificate configuration
- `postfix.*`: Postfix configuration (hostname, domain, allowed networks)
- `dovecot.*`: Dovecot configuration
- `vmail.*`: Service account configuration

## Required Files

Place these files in the role's `files/` directory:
- `dovecot.conf` - Dovecot configuration file
- `postfix.conf.j2` - Postfix configuration template

## Dependencies

None

## Example Playbook

```yaml
- name: Deploy Mail Server
  hosts: mail
  become: yes
  roles:
    - nix_mail_server
```

## Notes

- SSL certificates are self-signed
- Postfix uses Dovecot for authentication
- Mail storage uses vmail user/group
