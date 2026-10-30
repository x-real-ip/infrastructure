# Shared by every stack that talks to Proxmox, through a symlink. Edit it
# here, never through one of the links.
#
# The API token is read from PROXMOX_VE_API_TOKEN (tofu@pve!provider=<secret>).
# See ../README.md for how the token is created.
provider "proxmox" {
  endpoint = var.endpoint

  # The nodes use the default self-signed Proxmox certificate.
  insecure = true
}

variable "endpoint" {
  description = "Proxmox VE API endpoint. Point it at pve-b when pve-a is down."
  type        = string
  default     = "https://10.0.99.2:8006/"
}
