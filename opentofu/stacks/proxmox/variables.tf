variable "certificate_dir" {
  description = "Directory with <node>.crt and <node>.key for the node certificates."
  type        = string
  default     = "~/certs/proxmox"
}
