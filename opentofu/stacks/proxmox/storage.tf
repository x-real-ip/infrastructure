resource "proxmox_storage_directory" "local" {
  id      = "local"
  path    = "/var/lib/vz"
  content = ["backup", "import", "iso", "vztmpl"]

  # /var/lib/vz exists separately on every node. The provider defaults
  # shared to true for directory storage.
  shared = false

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
