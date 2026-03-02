resource "openstack_networking_port_v2" "blue1_ports" {
  for_each   = var.blue1_instances
  name       = "${each.key}-port"
  network_id = openstack_networking_network_v2.blue1.id

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.blue1.id
    ip_address = each.value.ip
  }
}

data "openstack_images_image_v2" "blue1_images" {
  for_each    = var.blue1_instances
  # Resolve an image name to a stable ID for block-device boot.
  # Without this, instances may boot from ephemeral disk (no Cinder volume attached).
  name        = each.value.image
  most_recent = true
}

resource "openstack_compute_instance_v2" "blue1_vms" {
  for_each = var.blue1_instances

  name        = each.key
  flavor_name = each.value.flavor
  key_pair    = "CharlieSpring26"

  # Boot-from-volume (Cinder) instead of ephemeral root disk.
  # This is what makes OpenStack show an attached volume for the OS disk.
  block_device {
    uuid                  = data.openstack_images_image_v2.blue1_images[each.key].id
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = each.value.root_volume_size
    boot_index            = 0
    delete_on_termination = true
  }

  network {
    port = openstack_networking_port_v2.blue1_ports[each.key].id
  }
}

