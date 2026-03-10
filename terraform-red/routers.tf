// Provide outbound internet (SNAT) for the existing `charlie-red-team` network.
// Project already has a router named `red-team` with external gateway on MAIN-NAT.
// We only attach the `charlie-red-team` subnet as an interface to that existing router.

data "openstack_networking_router_v2" "red_team" {
  name = "red-team"
}

resource "openstack_networking_router_interface_v2" "charlie_red_team" {
  router_id = data.openstack_networking_router_v2.red_team.id
  subnet_id = data.openstack_networking_subnet_v2.charlie_red_team.id
}

