# Adopt the configuration that already exists on the cluster. Once the first
# apply has brought everything into the state these blocks are no-ops and can
# be removed.

import {
  to = proxmox_cluster_options.this
  id = "cluster"
}

import {
  for_each = local.nodes
  to       = proxmox_virtual_environment_dns.node[each.key]
  id       = each.key
}

import {
  for_each = local.nodes
  to       = proxmox_virtual_environment_time.node[each.key]
  id       = each.key
}

import {
  for_each = local.node_bridges
  to       = proxmox_network_linux_bridge.node[each.key]
  id       = each.key
}

import {
  for_each = local.node_apt_repositories
  to       = proxmox_apt_standard_repository.node[each.key]
  id       = "${each.value.node},${each.value.handle}"
}

import {
  for_each = local.node_apt_repositories
  to       = proxmox_apt_repository.node[each.key]
  id       = "${each.value.node},${each.value.file},0"
}

import {
  to = proxmox_storage_directory.local
  id = "local"
}

import {
  to = proxmox_storage_zfspool.vm_storage
  id = "vm-storage"
}
