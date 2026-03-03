data "openstack_networking_network_v2" "charlie_red_team" {
  name = "charlie-red-team"
}

data "openstack_networking_subnet_v2" "charlie_red_team" {
  network_id = data.openstack_networking_network_v2.charlie_red_team.id
}

resource "openstack_networking_port_v2" "kali_ports" {
  for_each   = var.kali_instances
  name       = each.value.hostname
  network_id = data.openstack_networking_network_v2.charlie_red_team.id

  fixed_ip {
    subnet_id  = data.openstack_networking_subnet_v2.charlie_red_team.id
    ip_address = each.value.ip
  }
}

data "openstack_images_image_v2" "kali_images" {
  for_each    = var.kali_instances
  name        = each.value.image
  most_recent = true
}

resource "openstack_compute_instance_v2" "kali" {
  for_each = var.kali_instances

  name        = each.value.hostname
  flavor_name = each.value.flavor
  key_pair    = "CharlieSpring26"

  block_device {
    uuid                  = data.openstack_images_image_v2.kali_images[each.key].id
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = each.value.root_volume_size
    boot_index            = 0
    delete_on_termination = true
  }

  network {
    port = openstack_networking_port_v2.kali_ports[each.key].id
  }
}

# Victim instances (Windows Server, Windows 10, Linux)
resource "openstack_networking_port_v2" "victim_ports" {
  for_each   = var.victim_instances
  name       = "${each.value.hostname}-port"
  network_id = data.openstack_networking_network_v2.charlie_red_team.id

  fixed_ip {
    subnet_id  = data.openstack_networking_subnet_v2.charlie_red_team.id
    ip_address = each.value.ip
  }
}

data "openstack_images_image_v2" "victim_images" {
  for_each    = var.victim_instances
  name        = each.value.image
  most_recent = true
}

resource "openstack_compute_instance_v2" "victim" {
  for_each = var.victim_instances

  name        = each.value.hostname
  flavor_name = each.value.flavor
  key_pair    = "CharlieSpring26"

  block_device {
    uuid                  = data.openstack_images_image_v2.victim_images[each.key].id
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = each.value.root_volume_size
    boot_index            = 0
    delete_on_termination = true
  }

  network {
    port = openstack_networking_port_v2.victim_ports[each.key].id
  }
}

