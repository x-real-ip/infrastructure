variable "proxmox_api_token_secret" {
}

variable "template_name" {
  default = "k3s-template"
}

variable "k3s_master_01" {
  default = "192.168.1.11"
}

variable "k3s_master_02" {
  default = "192.168.1.12"
}

variable "k3s_master_03" {
  default = "192.168.1.13"
}

variable "gateway" {
  default = "192.168.1.1"
}

variable "ssh_public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key_path" {
  default   = "~/.ssh/id_rsa"
  sensitive = true
}

variable "k3s_masters_memory" {
  default = "4096"
}

variable "k3s_workers_memory" {
  default = "4096"
}

variable "k3s_masters_cores" {
  default = 8
}

variable "k3s_workers_cores" {
  default = 8
}


variable "k3s_number_worker_nodes" {
  default = 1
}
