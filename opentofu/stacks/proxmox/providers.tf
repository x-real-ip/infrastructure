# The API token is read from PROXMOX_VE_API_TOKEN (tofu@pve!provider=<secret>).
# See ../../README.md for how the token is created.
provider "proxmox" {
  endpoint = var.endpoint

  # The nodes use the default self-signed Proxmox certificate.
  insecure = true
}
