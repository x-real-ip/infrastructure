terraform {
  required_version = ">= 1.10"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.116"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.12"
    }
  }
}
