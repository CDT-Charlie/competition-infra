resource "openstack_networking_port_v2" "blue1_ports" {
  for_each   = var.blue1_instances
  name       = "${each.key}-port"
  network_id = openstack_networking_network_v2.blue1.id

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.blue1.id
    ip_address = each.value.ip
  }
}

resource "openstack_compute_instance_v2" "blue1_vms" {
  for_each = var.blue1_instances

  name        = each.key
  flavor_name = each.value.flavor
  image_name  = each.value.image
  key_pair    = "CharlieSpring26"

  network {
    port = openstack_networking_port_v2.blue1_ports[each.key].id
  }
}

