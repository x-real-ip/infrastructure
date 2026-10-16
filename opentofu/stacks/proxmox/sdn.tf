# One vnet per VLAN on the guest trunk vmbr2, so a guest attaches to "iot"
# instead of vmbr2 with tag 30. Guests that need the trunk itself, such as
# OPNsense, keep using vmbr2 directly.
resource "proxmox_sdn_zone_vlan" "lan" {
  id     = "lan"
  bridge = proxmox_network_linux_bridge.node["pve-a:vmbr2"].name
  nodes  = keys(local.nodes)

  depends_on = [proxmox_sdn_applier.finalizer]
}

resource "proxmox_sdn_vnet" "vlan" {
  for_each = local.vlans

  id    = each.key
  zone  = proxmox_sdn_zone_vlan.lan.id
  tag   = each.value
  alias = "VLAN ${each.value}"

  depends_on = [proxmox_sdn_applier.finalizer]
}

# SDN changes are staged until they are applied, which reloads the network
# configuration on every node.
resource "proxmox_sdn_applier" "this" {
  lifecycle {
    replace_triggered_by = [
      proxmox_sdn_zone_vlan.lan,
      proxmox_sdn_vnet.vlan,
    ]
  }

  depends_on = [
    proxmox_sdn_zone_vlan.lan,
    proxmox_sdn_vnet.vlan,
  ]
}

# Applies the pending SDN configuration after zones and vnets are destroyed.
resource "proxmox_sdn_applier" "finalizer" {
}
