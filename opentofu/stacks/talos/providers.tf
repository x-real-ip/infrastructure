# The proxmox provider is configured in proxmox.tf (shared). The talos
# provider needs no configuration: every resource gets the client
# configuration from talos_machine_secrets.
provider "talos" {}
