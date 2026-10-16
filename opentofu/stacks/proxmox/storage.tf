resource "proxmox_storage_directory" "local" {
  id      = "local"
  path    = "/var/lib/vz"
  content = ["backup", "iso", "vztmpl"]

  lifecycle {
    prevent_destroy = true
  }
}

# ZFS pool on both nodes, used for VM disks and storage replication.
resource "proxmox_storage_zfspool" "vm_storage" {
  id             = "vm-storage"
  zfs_pool       = "vm-storage"
  content        = ["images", "rootdir"]
  thin_provision = false

  lifecycle {
    prevent_destroy = true
  }
}
