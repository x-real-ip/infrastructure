resource "proxmox_virtual_environment_pool" "this" {
  for_each = local.pools

  pool_id = each.key
  comment = each.value.comment
}

resource "proxmox_pool_membership" "guest" {
  for_each = local.pool_memberships

  pool_id = proxmox_virtual_environment_pool.this[each.value.pool].id
  vm_id   = each.value.vm_id
}
