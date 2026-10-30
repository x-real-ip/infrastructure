# Shared by every stack through a symlink, so all state is encrypted the same
# way. Edit it here, never through one of the links.
#
# The state is committed to git, so it must never be written unencrypted.
# The passphrase comes from TF_VAR_state_passphrase (stored in Bitwarden).
terraform {
  encryption {
    key_provider "pbkdf2" "main" {
      passphrase = var.state_passphrase
    }

    method "aes_gcm" "main" {
      keys = key_provider.pbkdf2.main
    }

    state {
      method   = method.aes_gcm.main
      enforced = true
    }

    plan {
      method   = method.aes_gcm.main
      enforced = true
    }
  }
}

variable "state_passphrase" {
  description = "Passphrase for state and plan encryption. Set via TF_VAR_state_passphrase."
  type        = string
  sensitive   = true
}
