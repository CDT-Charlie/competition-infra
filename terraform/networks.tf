resource "openstack_networking_network_v2" "admin" {
    name = "admin_net"
    admin_state_up = true
}

resource "openstack_networking_subnet_v2" "admin" {
    name = "admin_subnet"
    network_id = openstack_networking_network_v2.admin.id

    cidr = "10.100.0.0/24"
    ip_version = 4

    dns_nameservers = ["1.1.1.1", "8.8.8.8"]
}

resource "openstack_networking_network_v2" "red" {
    name = "red_net"
    admin_state_up = true
}

resource "openstack_networking_subnet_v2" "red" {
    name = "red_subnet"
    network_id = openstack_networking_network_v2.red.id
    cidr = "10.100.1.0/24"
    ip_version = 4

    dns_nameservers = ["1.1.1.1", "8.8.8.8"]
}

resource "openstack_networking_network_v2" "blue1" {
    name = "blue1_net"
    admin_state_up = true
}

resource "openstack_networking_subnet_v2" "blue1" {
    name = "blue1_subnet"
    network_id = openstack_networking_network_v2.blue1.id
    cidr = "10.100.2.0/24"
    ip_version = 4

    dns_nameservers = ["1.1.1.1", "8.8.8.8"]
}

resource "openstack_networking_network_v2" "blue2" {
    name = "blue2_net"
    admin_state_up = true
}

resource "openstack_networking_subnet_v2" "blue2" {
    name = "blue2_subnet"
    network_id = openstack_networking_network_v2.blue2.id
    cidr = "10.100.3.0/24"
    ip_version = 4

    dns_nameservers = ["1.1.1.1", "8.8.8.8"]
}