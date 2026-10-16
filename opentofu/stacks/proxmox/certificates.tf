# Web interface and API certificate per node, issued by the stamx CA. The
# files stay outside git (see ../../README.md); the private key ends up in
# the encrypted state.
resource "proxmox_virtual_environment_certificate" "node" {
  for_each = local.nodes

  node_name         = each.key
  certificate       = file("${pathexpand(var.certificate_dir)}/${each.key}.crt")
  private_key       = file("${pathexpand(var.certificate_dir)}/${each.key}.key")
  certificate_chain = file("${pathexpand(var.certificate_dir)}/ca.crt")
}
