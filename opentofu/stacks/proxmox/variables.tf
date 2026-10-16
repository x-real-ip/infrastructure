variable "state_passphrase" {
  description = "Passphrase for state and plan encryption. Set via TF_VAR_state_passphrase."
  type        = string
  sensitive   = true
}

variable "endpoint" {
  description = "Proxmox VE API endpoint. Point it at pve-b when pve-a is down."
  type        = string
  default     = "https://10.0.99.2:8006/"
}
