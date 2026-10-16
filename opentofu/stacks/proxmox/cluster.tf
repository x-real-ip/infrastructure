resource "proxmox_cluster_options" "this" {
  keyboard   = "en-us"
  mac_prefix = "BC:24:11"
  # Proxmox returns the description with a trailing newline; without it the
  # provider reports an inconsistent result after every apply.
  description = "Managed by OpenTofu: infrastructure/opentofu/stacks/proxmox\n"

  # Live-migrate HA guests to the other node before a planned shutdown or
  # reboot, so OPNsense keeps routing.
  ha_shutdown_policy = "migrate"
}
