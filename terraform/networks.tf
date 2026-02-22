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