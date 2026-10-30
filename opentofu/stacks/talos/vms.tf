# The VMs are cattle: etcd and the workloads replicate themselves, so there is
# no HA or storage replication for them in the proxmox stack.
resource "proxmox_virtual_environment_vm" "node" {
  for_each = local.vms

  name        = each.key
  node_name   = each.value.host
  vm_id       = each.value.vm_id
  pool_id     = local.pool
  description = "Talos ${each.value.role}, managed by OpenTofu: infrastructure/opentofu/stacks/talos"
  tags        = ["talos", local.cluster_name, each.value.role]

  machine         = "q35"
  scsi_hardware   = "virtio-scsi-single"
  on_boot         = true
  stop_on_destroy = true

  agent {
    enabled = true
  }

  cpu {
    cores = each.value.cpu
    type  = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  network_device {
    bridge = local.network.vnet
  }

  disk {
    datastore_id = local.disk_datastore
    interface    = "scsi0"
    import_from  = proxmox_download_file.talos[each.value.host].id
    size         = each.value.disk
    iothread     = true
    discard      = "on"
    ssd          = true
  }

  operating_system {
    type = "l26"
  }

  # Talos (platform nocloud) takes its hostname, address and DNS servers from
  # this cloud-init drive on every boot, so they are not repeated in the
  # machine configuration.
  initialization {
    datastore_id = local.disk_datastore

    ip_config {
      ipv4 {
        address = "${each.value.ip}/${local.network.cidr}"
        gateway = local.network.gateway
      }
    }

    dns {
      servers = local.network.dns
    }
  }
}
