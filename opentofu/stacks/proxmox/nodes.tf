resource "proxmox_virtual_environment_dns" "node" {
  for_each = local.nodes

  node_name = each.key
  domain    = local.domain
  servers   = local.dns
}

resource "proxmox_virtual_environment_time" "node" {
  for_each = local.nodes

  node_name = each.key
  time_zone = local.timezone
}

resource "proxmox_network_linux_bridge" "node" {
  for_each = local.node_bridges

  node_name  = each.value.node
  name       = each.value.name
  comment    = each.value.comment
  ports      = [each.value.port]
  address    = each.value.address
  gateway    = each.value.gateway
  vlan_aware = each.value.vlan_aware
  vids       = each.value.vlan_aware ? "2-4094" : null

  # vmbr0 carries the management address of the node. Recreating any bridge
  # cuts the node or its guests off the network.
  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_apt_standard_repository" "node" {
  for_each = local.node_apt_repositories

  node   = each.value.node
  handle = each.value.handle
}

resource "proxmox_apt_repository" "node" {
  for_each = local.node_apt_repositories

  node      = proxmox_apt_standard_repository.node[each.key].node
  file_path = proxmox_apt_standard_repository.node[each.key].file_path
  index     = proxmox_apt_standard_repository.node[each.key].index
  enabled   = each.value.enabled
}
