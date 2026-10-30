locals {
  cluster_name = "talos"

  # Kubernetes API on a layer-2 VIP shared by the control planes. k3s keeps
  # 10.0.100.100 until it is decommissioned.
  cluster_vip = "10.0.100.110"

  # OS upgrades go through `talosctl upgrade` (see ../../README.md). Changing
  # kubernetes_version runs Talos's upgrade-k8s on the next apply.
  talos_version      = "v1.14.4"
  kubernetes_version = "v1.37.1"

  # iscsi-tools and util-linux-tools are needed by democratic-csi.
  talos_extensions = [
    "siderolabs/qemu-guest-agent",
    "siderolabs/iscsi-tools",
    "siderolabs/util-linux-tools",
  ]

  # Flannel and kube-proxy are disabled so Cilium can be installed afterwards.
  use_cilium = true

  # VLAN 100 (systems), through the SDN vnet of the proxmox stack.
  network = {
    vnet    = "systems"
    cidr    = 24
    gateway = "10.0.100.1"
    dns     = ["10.0.100.1"]
  }

  # The image is downloaded to local storage on every host and imported into
  # vm-storage when a VM is created.
  image_datastore = "local"
  disk_datastore  = "vm-storage"
  pool            = "kubernetes"

  # Sizing per role. A node can override any of these in local.nodes.
  roles = {
    controlplane = { cpu = 2, memory = 4096, disk = 32 }
    worker       = { cpu = 4, memory = 8192, disk = 64 }
  }

  # With two hosts, etcd keeps quorum when pve-b is down but not when pve-a
  # (two control planes) is. A third host or a witness would fix that.
  nodes = {
    talos-mst-01 = { role = "controlplane", host = "pve-a", vm_id = 401, ip = "10.0.100.111" }
    talos-mst-02 = { role = "controlplane", host = "pve-b", vm_id = 402, ip = "10.0.100.112" }
    talos-mst-03 = { role = "controlplane", host = "pve-a", vm_id = 403, ip = "10.0.100.113" }
    talos-wkr-01 = { role = "worker", host = "pve-a", vm_id = 411, ip = "10.0.100.121" }
    talos-wkr-02 = { role = "worker", host = "pve-b", vm_id = 412, ip = "10.0.100.122" }
  }

  vms = { for name, n in local.nodes : name => merge(local.roles[n.role], n) }

  hosts            = toset([for n in values(local.nodes) : n.host])
  controlplane_ips = [for n in values(local.nodes) : n.ip if n.role == "controlplane"]

  # values() is ordered by key, so this is always talos-mst-01.
  bootstrap_ip = local.controlplane_ips[0]
}
