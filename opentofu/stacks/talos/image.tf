# Talos image with the extensions from locals.tf, built by the Image Factory.
resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = local.talos_extensions
      }
    }
  })
}

data "talos_image_factory_urls" "this" {
  talos_version = local.talos_version
  schematic_id  = talos_image_factory_schematic.this.id
  platform      = "nocloud"
  architecture  = "amd64"
}

# local is not shared, so every host needs its own copy. The "import" content
# type lets the VMs import the disk through the API, without SSH. The factory
# links the .xz image, which Proxmox cannot decompress; .zst is served too.
resource "proxmox_download_file" "talos" {
  for_each = local.hosts

  node_name               = each.key
  content_type            = "import"
  datastore_id            = local.image_datastore
  file_name               = "talos-${local.talos_version}-${substr(talos_image_factory_schematic.this.id, 0, 8)}-nocloud-amd64.raw"
  url                     = "${trimsuffix(data.talos_image_factory_urls.this.urls.disk_image, ".xz")}.zst"
  decompression_algorithm = "zst"
  overwrite               = false
}
