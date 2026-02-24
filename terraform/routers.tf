# this data block looks it up by name from the openrc file you source, so you don’t hardcode an ID
data "openstack_networking_network_v2" "external" {
    name = "MAIN-NAT"
}

resource "openstack_networking_router_v2" "main" {
    name = "main_router"
    admin_state_up = true

    # this sets the WAN side of the router to the provider network
    external_network_id = data.openstack_networking_network_v2.external.id  
}

# Attach all the subnets to the same router by defining interfaces
resource "openstack_networking_router_interface_v2" "admin" {
    router_id = openstack_networking_router_v2.main.id
    subnet_id = openstack_networking_subnet_v2.admin.id
}

resource "openstack_networking_router_interface_v2" "red" {
    router_id = openstack_networking_router_v2.main.id
    subnet_id = openstack_networking_subnet_v2.red.id
}

resource "openstack_networking_router_interface_v2" "blue1" {
    router_id = openstack_networking_router_v2.main.id
    subnet_id = openstack_networking_subnet_v2.blue1.id
}

resource "openstack_networking_router_interface_v2" "blue2" {
    router_id = openstack_networking_router_v2.main.id
    subnet_id = openstack_networking_subnet_v2.blue2.id
}
