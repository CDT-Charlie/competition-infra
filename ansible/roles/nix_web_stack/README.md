# Nginx + MySQL Web Stack Role

Deploys a web stack using Docker containers: Nginx, MySQL, and PHP.

## Features

- Installs Docker
- Creates Docker network
- Deploys MySQL container with database initialization
- Deploys PHP container with MySQL support
- Deploys Nginx container as reverse proxy
- Configures all containers to work together

## Requirements

- Debian/Ubuntu Linux
- Ansible 2.9+
- Docker collection: `ansible-galaxy collection install community.docker`
- Root or sudo access

## Role Variables

All variables use centralized `group_vars/all.yml` by default. See `defaults/main.yml` for role-specific defaults.

### Key Variables

- `web.root`: Web root directory
- `web.nginx_port`: Nginx port (default: 80)
- `docker.network_name`: Docker network name
- `docker.mysql.*`: MySQL container configuration
- `docker.php.*`: PHP container configuration
- `docker.nginx.*`: Nginx container configuration

## Required Files

Place these files in the role's `files/` directory:
- `index.php` or use template `templates/index.php.j2`
- `nginx.conf` - Nginx configuration
- `Dockerfile.php` - PHP Dockerfile with MySQL support

## Dependencies

- `community.docker` collection

## Example Playbook

```yaml
- name: Deploy Web Stack
  hosts: webservers
  become: yes
  roles:
    - nix_web_stack
```

## Notes

- Database initialization script is generated from template
- All containers use restart_policy: always
- Containers communicate via Docker network
