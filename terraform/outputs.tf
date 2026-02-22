output "admin_network_id" {
  value = openstack_networking_network_v2.admin.id
}

output "admin_subnet_id" {
  value = openstack_networking_subnet_v2.admin.id
}

output "admin_router_id" {
  value = openstack_networking_router_v2.admin.id
}

output "external_network_id" {
  value = data.openstack_networking_network_v2.external.id
}