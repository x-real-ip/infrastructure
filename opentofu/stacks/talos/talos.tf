resource "talos_machine_secrets" "this" {
  talos_version = local.talos_version
}

data "talos_client_configuration" "this" {
  cluster_name         = local.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = local.controlplane_ips
  nodes                = [for n in values(local.nodes) : n.ip]
}

locals {
  # Applied to every node.
  common_patch = {
    machine = {
      install = {
        disk  = "/dev/sda"
        image = data.talos_image_factory_urls.this.urls.installer
      }
    }
  }

  # Leaves the cluster without a CNI and kube-proxy, for Cilium.
  cilium_patch = {
    cluster = {
      network = { cni = { name = "none" } }
      proxy   = { disabled = true }
    }
  }

  # Applied to the control planes only.
  controlplane_patch = {
    machine = {
      network = {
        interfaces = [{
          deviceSelector = { physical = true }
          vip            = { ip = local.cluster_vip }
        }]
      }
    }
  }
}

data "talos_machine_configuration" "node" {
  for_each = local.nodes

  cluster_name       = local.cluster_name
  cluster_endpoint   = "https://${local.cluster_vip}:6443"
  machine_type       = each.value.role
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = local.talos_version
  kubernetes_version = local.kubernetes_version
  docs               = false
  examples           = false

  config_patches = [
    for patch in concat(
      [local.common_patch],
      local.use_cilium ? [local.cilium_patch] : [],
      each.value.role == "controlplane" ? [local.controlplane_patch] : [],
    ) : yamlencode(patch)
  ]
}

resource "talos_machine" "node" {
  for_each = local.nodes

  client_configuration  = talos_machine_secrets.this.client_configuration
  machine_configuration = data.talos_machine_configuration.node[each.key].machine_configuration
  node                  = each.value.ip

  # talos_cluster owns the Kubernetes version, see locals.tf.
  ignore_kubernetes_upgrade_drift = true

  depends_on = [proxmox_virtual_environment_vm.node]
}

# Bootstraps etcd once and runs upgrade-k8s when kubernetes_version changes.
resource "talos_cluster" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.bootstrap_ip
  control_plane_nodes  = local.controlplane_ips
  kubernetes_version   = local.kubernetes_version

  depends_on = [talos_machine.node]
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.bootstrap_ip

  depends_on = [talos_cluster.this]
}
