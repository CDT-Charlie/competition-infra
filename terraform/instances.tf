resource "openstack_networking_port_v2" "instance_ports" {
  for_each   = var.instances
  name       = "${each.key}-port"
  network_id = local.networks[each.value.network].network_id

  fixed_ip {
    subnet_id  = local.networks[each.value.network].subnet_id
    ip_address = each.value.ip
  }
}

data "openstack_images_image_v2" "instance_images" {
  for_each    = var.instances
  name        = each.value.image
  most_recent = true
}

resource "openstack_compute_instance_v2" "instances" {
  for_each = var.instances

  name        = each.key
  flavor_name = each.value.flavor
  key_pair    = "CharlieSpring26"

  block_device {
    uuid                  = data.openstack_images_image_v2.instance_images[each.key].id
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = each.value.root_volume_size
    boot_index            = 0
    delete_on_termination = true
  }

  network {
    port = openstack_networking_port_v2.instance_ports[each.key].id
  }
}
