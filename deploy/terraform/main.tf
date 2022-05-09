terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.9"
    }
  }
}

resource "random_password" "k3s_token" {
  length  = 16
  special = false
}

provider "proxmox" {
  pm_api_url          = "https://proxmox.lan:8006/api2/json"
  pm_tls_insecure     = true
  pm_api_token_id     = "terraform-prov@pve!mytoken"
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_parallel         = 1
  pm_timeout          = 600
}

resource "proxmox_vm_qemu" "k3s-master-01" {
  name        = "k3s-master-01"
  vmid        = 211
  ipconfig0   = "ip=${var.k3s_master_01}/24,gw=${var.gateway}"
  nameserver  = var.gateway
  count       = 1
  target_node = "pve"
  clone       = var.template_name
  os_type     = "cloud-init"
  agent       = 1
  memory      = var.k3s_masters_memory
  cores       = var.k3s_masters_cores
  cpu         = "host"

  sshkeys = file("${var.ssh_public_key_path}")

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  disk {
    slot     = 0
    size     = "32G"
    type     = "scsi"
    storage  = "vm-storage"
    iothread = 1
  }

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  connection {
    type        = "ssh"
    user        = "coen"
    private_key = file("${var.ssh_private_key_path}")
    host        = var.k3s_master_01
  }

  provisioner "file" {
    source      = "manifests/"
    destination = "/tmp"
  }

  provisioner "file" {
    destination = "/tmp/k3s_bootstrap.sh"
    content = templatefile("k3s_bootstrap.sh.tpl",
      {
        k3s_token           = random_password.k3s_token.result,
        k3s_cluster_init_ip = var.k3s_master_01
      }
    )
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "chmod +x /tmp/k3s_bootstrap.sh",
      "sudo /tmp/k3s_bootstrap.sh"
    ]
  }
}

resource "proxmox_vm_qemu" "k3s-master-02" {

  depends_on = [
    proxmox_vm_qemu.k3s-master-01[0]
  ]

  name        = "k3s-master-02"
  vmid        = 212
  ipconfig0   = "ip=${var.k3s_master_02}/24,gw=${var.gateway}"
  nameserver  = var.gateway
  count       = 1
  target_node = "pve"
  clone       = var.template_name
  os_type     = "cloud-init"
  agent       = 1
  memory      = var.k3s_masters_memory
  cores       = var.k3s_masters_cores
  cpu         = "host"

  sshkeys = file("${var.ssh_public_key_path}")

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  disk {
    slot     = 0
    size     = "32G"
    type     = "scsi"
    storage  = "vm-storage"
    iothread = 1
  }

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  connection {
    type        = "ssh"
    user        = "coen"
    private_key = file("${var.ssh_private_key_path}")
    host        = var.k3s_master_02
  }

  provisioner "file" {
    destination = "/tmp/k3s_bootstrap.sh"
    content = templatefile("k3s_bootstrap.sh.tpl",
      {
        k3s_token           = random_password.k3s_token.result,
        k3s_cluster_init_ip = var.k3s_master_01
      }
    )
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "chmod +x /tmp/k3s_bootstrap.sh",
      "sudo /tmp/k3s_bootstrap.sh"
    ]
  }
}

resource "proxmox_vm_qemu" "k3s-master-03" {

  depends_on = [
    proxmox_vm_qemu.k3s-master-02[0]
  ]

  name        = "k3s-master-03"
  vmid        = 213
  ipconfig0   = "ip=${var.k3s_master_03}/24,gw=${var.gateway}"
  nameserver  = var.gateway
  count       = 1
  target_node = "pve"
  clone       = var.template_name
  os_type     = "cloud-init"
  agent       = 1
  memory      = var.k3s_masters_memory
  cores       = var.k3s_masters_cores
  cpu         = "host"

  sshkeys = file("${var.ssh_public_key_path}")

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  disk {
    slot     = 0
    size     = "32G"
    type     = "scsi"
    storage  = "vm-storage"
    iothread = 1
  }

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  connection {
    type        = "ssh"
    user        = "coen"
    private_key = file("${var.ssh_private_key_path}")
    host        = var.k3s_master_03
  }

  provisioner "file" {
    destination = "/tmp/k3s_bootstrap.sh"
    content = templatefile("k3s_bootstrap.sh.tpl",
      {
        k3s_token           = random_password.k3s_token.result,
        k3s_cluster_init_ip = var.k3s_master_01
      }
    )
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "chmod +x /tmp/k3s_bootstrap.sh",
      "sudo /tmp/k3s_bootstrap.sh"
    ]
  }
}

resource "proxmox_vm_qemu" "k3s-workers" {

  depends_on = [
    proxmox_vm_qemu.k3s-master-03[0]
  ]

  name        = "k3s-worker-0${count.index + 1}"
  vmid        = "2${count.index + 14}"
  ipconfig0   = "ip=192.168.1.${count.index + 14}/24,gw=${var.gateway}"
  nameserver  = var.gateway
  count       = var.k3s_number_worker_nodes
  target_node = "pve"
  clone       = var.template_name
  os_type     = "cloud-init"
  agent       = 1
  memory      = var.k3s_workers_memory
  cores       = var.k3s_workers_cores
  cpu         = "host"

  sshkeys = file("${var.ssh_public_key_path}")

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  disk {
    slot     = 0
    size     = "32G"
    type     = "scsi"
    storage  = "vm-storage"
    iothread = 1
  }

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  connection {
    type        = "ssh"
    user        = "coen"
    private_key = file("${var.ssh_private_key_path}")
    host        = "192.168.1.${count.index + 14}"
  }

  provisioner "file" {
    destination = "/tmp/k3s_bootstrap.sh"
    content = templatefile("k3s_bootstrap.sh.tpl",
      {
        k3s_token           = random_password.k3s_token.result,
        k3s_cluster_init_ip = var.k3s_master_01
      }
    )
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "chmod +x /tmp/k3s_bootstrap.sh",
      "sudo /tmp/k3s_bootstrap.sh"
    ]
  }
}
