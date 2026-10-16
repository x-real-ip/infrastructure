locals {
  domain    = "lan.stamx.nl"
  timezone  = "Europe/Amsterdam"
  dns       = ["10.0.99.1"]
  gateway   = "10.0.99.1"
  mgmt_cidr = 24

  nodes = {
    pve-a = { mgmt_ip = "10.0.99.2" }
    pve-b = { mgmt_ip = "10.0.99.3" }
  }

  # Identical on every node: nic0 is the onboard NIC, nic1 and nic2 are the
  # PCI card. vmbr0 carries the management address, vmbr1 and vmbr2 are
  # VLAN-aware trunks for OPNsense (wan) and the guests (lan).
  bridges = {
    vmbr0 = { port = "nic0", comment = "mgmt", vlan_aware = false }
    vmbr1 = { port = "nic1", comment = "wan", vlan_aware = true }
    vmbr2 = { port = "nic2", comment = "lan", vlan_aware = true }
  }

  node_bridges = merge([
    for node, n in local.nodes : {
      for name, b in local.bridges : "${node}:${name}" => merge(b, {
        node    = node
        name    = name
        address = name == "vmbr0" ? "${n.mgmt_ip}/${local.mgmt_cidr}" : null
        gateway = name == "vmbr0" ? local.gateway : null
      })
    }
  ]...)

  # enabled = false keeps the repository in the sources file but switched off.
  apt_repositories = {
    "enterprise"            = { enabled = false, file = "/etc/apt/sources.list.d/pve-enterprise.sources" }
    "no-subscription"       = { enabled = true, file = "/etc/apt/sources.list.d/proxmox.sources" }
    "ceph-squid-enterprise" = { enabled = false, file = "/etc/apt/sources.list.d/ceph.sources" }
  }

  node_apt_repositories = merge([
    for node in keys(local.nodes) : {
      for handle, r in local.apt_repositories : "${node}:${handle}" => merge(r, {
        node   = node
        handle = handle
      })
    }
  ]...)
}
