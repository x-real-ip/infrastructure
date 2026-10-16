# The SAS HBA with the TrueNAS data disks, by name instead of PCI address.
# Each node has its own card; truenas-a runs on pve-a, truenas-b on pve-b.
resource "proxmox_hardware_mapping_pci" "lsi_hba" {
  name    = "lsi-hba"
  comment = "LSI SAS2008 with the TrueNAS data disks"

  map = [
    {
      node         = "pve-a"
      path         = "0000:01:00.0"
      id           = "1000:0072"
      subsystem_id = "1028:1f1c"
      iommu_group  = 2
    },
    {
      node         = "pve-b"
      path         = "0000:01:00.0"
      id           = "1000:0072"
      subsystem_id = "1734:1177"
      iommu_group  = 2
    },
  ]
}
