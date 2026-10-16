locals {
  domain    = "lan.stamx.nl"
  timezone  = "Europe/Amsterdam"
  dns       = ["10.0.99.1"]
  gateway   = "10.0.99.1"
  mgmt_cidr = 24

  nodes = {
    pve-a = {
      mgmt_ip = "10.0.99.2"
      peer    = "pve-b"
      notes   = <<-EOT
        Managed by OpenTofu.

        - Boot disk: Force MP500 (ext4 on LVM)
        - vm-storage: Intel SSDPEKNW010T8 (ZFS)
        - HBA: LSI SAS2008, passed through to truenas-a
      EOT
    }
    pve-b = {
      mgmt_ip = "10.0.99.3"
      peer    = "pve-a"
      notes   = <<-EOT
        Managed by OpenTofu.

        - Boot disk: Kingston SUV400S37240G (ext4 on LVM)
        - vm-storage: ADATA SX8200PNP (ZFS)
        - HBA: LSI SAS2008, passed through to truenas-b
      EOT
    }
  }

  # VLANs from documentation/docs/network.md that guests can attach to.
  # VLAN 99 (management) is untagged on the switch ports of vmbr2, so it has
  # no vnet: a guest that needs it uses vmbr2 without a tag.
  vlans = {
    private = 10
    guest   = 20
    iot     = 30
    not     = 40
    kids    = 50
    systems = 100
  }

  # Guests whose disks are replicated from pve-a to pve-b every 15 minutes.
  replicated_guests = {
    opnsense     = 1000
    k3s-mst-01   = 301
    k3s-mst-02   = 302
    k3s-mst-03   = 303
    k3s-template = 999
  }

  pools = {
    infra = {
      comment = "Network and storage"
      guests  = { opnsense = 1000, truenas-a = 100, truenas-b = 200 }
    }
    kubernetes = {
      comment = "Kubernetes cluster"
      guests  = { k3s-mst-01 = 301, k3s-mst-02 = 302, k3s-mst-03 = 303, k3s-template = 999 }
    }
  }

  pool_memberships = merge([
    for pool, p in local.pools : {
      for name, vm_id in p.guests : name => { pool = pool, vm_id = vm_id }
    }
  ]...)

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
