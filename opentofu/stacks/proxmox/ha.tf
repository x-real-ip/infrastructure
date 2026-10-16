resource "proxmox_haresource" "opnsense" {
  resource_id = "vm:1000"
  state       = "started"
}

# Prefer pve-a, fail over to pve-b and move back once pve-a is online again.
resource "proxmox_harule" "opnsense_prefer_pve_a" {
  rule      = "opnsense-prefer-pve-a"
  type      = "node-affinity"
  comment   = "OPNsense runs on pve-a when it is available"
  resources = [proxmox_haresource.opnsense.resource_id]
  strict    = false

  nodes = {
    pve-a = 2
    pve-b = 1
  }
}

# Storage replication to pve-b keeps the disks of these guests on both nodes,
# which HA failover and fast migration need.
resource "proxmox_replication" "guest" {
  for_each = local.replicated_guests

  id     = "${each.value}-0"
  target = "pve-b"
  type   = "local"
}
