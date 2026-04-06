# Network lookup — add new networks here to support more VM networks.
locals {
  networks = {
    admin = {
      network_id = openstack_networking_network_v2.admin.id
      subnet_id  = openstack_networking_subnet_v2.admin.id
    }
    red = {
      network_id = openstack_networking_network_v2.alpha_charlie_red_team.id
      subnet_id  = openstack_networking_subnet_v2.alpha_red.id
    }
    blue1 = {
      network_id = openstack_networking_network_v2.blue1.id
      subnet_id  = openstack_networking_subnet_v2.blue1.id
    }
    blue2 = {
      network_id = openstack_networking_network_v2.blue2.id
      subnet_id  = openstack_networking_subnet_v2.blue2.id
    }
  }
}