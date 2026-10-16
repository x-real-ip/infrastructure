# Web interface and API certificate per node, issued by the stamx CA. The
# files stay outside git (see ../../README.md); the private key ends up in
# the encrypted state.
#
# There is no certificate_chain: the certificates are signed by the root CA
# directly, and clients already trust that root. The provider also never
# reads the chain back, which would show a change on every plan.
resource "proxmox_virtual_environment_certificate" "node" {
  for_each = local.nodes

  node_name   = each.key
  certificate = file("${pathexpand(var.certificate_dir)}/${each.key}.crt")
  private_key = file("${pathexpand(var.certificate_dir)}/${each.key}.key")
}
