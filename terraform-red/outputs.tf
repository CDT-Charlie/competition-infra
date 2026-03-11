# Output victim IPs for Ansible inventory (e.g. terraform output -json victim_ips)
output "victim_ips" {
  description = "Map of victim instance key -> { hostname, ip } for Ansible"
  value = {
    for k, v in var.victim_instances : k => {
      hostname = v.hostname
      ip      = v.ip
    }
  }
}
