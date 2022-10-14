#!/bin/bash

# Install k3s and dependencies on Debian distro.
# Writtin by Coen Stam.
# github@theautomation.nl
#

export manifest_location="/var/lib/rancher/k3s/server/manifests/"
export github_repo="https://github.com/theautomation/kubernetes-gitops.git"

# Set path variable for shutdown command.
export PATH=$PATH:/usr/sbin

# Set correct timezone.
echo "Set timezone..."
timedatectl set-timezone Europe/Amsterdam

# Set the system locale
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Update and install packages.
apt update && apt upgrade -y &&
  apt install -y \
    curl \
    wget \
    unzip \
    git

# ISCSI
echo -e "\nInstalling ISCSI and dependencies...\n"
apt install -y \
  open-iscsi \
  lsscsi \
  sg3-utils \
  multipath-tools \
  scsitools

# Create multipath config
tee /etc/multipath.conf <<-'EOF'
blacklist {
    devnode "sda"
}
defaults {
    user_friendly_names yes
    find_multipaths yes
}
EOF

# Create private registry yaml
tee /etc/rancher/k3s/registries.yaml <<-'EOF'
mirrors:
  harbor.k8s.lan:
    endpoint:
      - "https://harbor.k8s.lan:443"
configs:
  "harbor.k8s.lan":
    tls:
      insecure_skip_verify: true
EOF

systemctl enable multipath-tools.service
systemctl restart multipath-tools
systemctl enable open-iscsi.service
systemctl start open-iscsi

if [[ $HOSTNAME =~ master ]]; then
  # Setup masters
  if [[ $HOSTNAME = "k3s-master-01" ]]; then

    # Create dir for init manifests
    mkdir -p ${manifest_location}

    # Create sealedsecret custom certificate in init repo folder
    cat <<EOF >/var/lib/rancher/k3s/server/manifests/sealed-secret-customkeys-2.yaml
---
kind: Secret
apiVersion: v1
type: kubernetes.io/tls
metadata:
  name: sealed-secret-customkeys-2
  namespace: kube-system
  labels:
    sealedsecrets.bitnami.com/sealed-secrets-key: active
data:
  tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUZRVENDQXltZ0F3SUJBZ0lVU2lCYXdFaFR0Vms1RnQyd3diZWd3VGhxOVNNd0RRWUpLb1pJaHZjTkFRRUwKQlFBd01ERVdNQlFHQTFVRUF3d05jMlZoYkdWa0xYTmxZM0psZERFV01CUUdBMVVFQ2d3TmMyVmhiR1ZrTFhObApZM0psZERBZUZ3MHlNakEyTVRreE1ETXhNRFJhRncwek1qQTJNVFl4TURNeE1EUmFNREF4RmpBVUJnTlZCQU1NCkRYTmxZV3hsWkMxelpXTnlaWFF4RmpBVUJnTlZCQW9NRFhObFlXeGxaQzF6WldOeVpYUXdnZ0lpTUEwR0NTcUcKU0liM0RRRUJBUVVBQTRJQ0R3QXdnZ0lLQW9JQ0FRRHkrTkRrOXNPWCt3Yzl1YXlIbkJGdS9OS2Z6em0vdUJ2VgppODdLMUMxMnl2V01TVW05b0NzTDFwQzlCaUN6eXZVdDd6SG9jczZLaWl1RmFQQ3c5SHF2RTA2bUxKblhqL0dZCjNUQktVM1NkVTVPUHZmZVZNYW84clpUMGNhVXFXTHE1ckoxTE40QTNlRWUxSTlrVUQ4WmhRdmJBOTVIR3p4U1AKWVFUakcySkZKcFJpUkpPOG9aT3VPVTlsTTMrZ0Zsc2ZuSnB0K1NYbWpaYXlVYVczZndHMmR5OEpCREtrREhzQgpaR0tRWmk3L2NzWjZZcnhEY0hLZktNcTlOazJvYzBYK1hIYndoV2N4YjBKbm94MWhiVk56M3FsbisxeVUrM2t6ClVSVmhvTGpnazFoT3A1dVdzQXVhWVF4U3hkd3QwVDVSZXRVVHB5NlRocXdhVy81aXkvK3dlWllIWlZ6aTRJSDEKdVcxNTVqTzhzVGR4WXZCVUZQdStNWTNCK1JFQTlXejRzeGZMRXJyd1JKVi9UTkFGa1JkZ0huaEhtM05jc1RtVwpxM2U5c1lueVFBcml1WEhhUDZaRU1lWmVWWGY3UUZmM3lVU2pRL1dCTWRUOFJEQmRFdzRWUHFIc1cwQjQ3WkRQCmJabkhGOUtGem5CTHN6V0VLWVAyampMNWJxY2hDcFlIZGdhb2Q3Q3ZuNW1aai92N0M3QkNpdzZWVEtIQUhPbm8KR1FmYU1hV2dTZGMxNW8wR3JucUd0cTFGZm5GcW9oUlZMdjJOaXcyOEE0U25ZUEQxYTJiUWYxVk9OTHV5Nm0rKwpyUlltWEdidDBOZUEyWXVUL1J3ZThLTEkvc29SYmtGejZWK0UyWXVMSTZLaE44bVlxbE16QWlNS3h4VWRtclZuCnFCdGEvbkpsMFFJREFRQUJvMU13VVRBZEJnTlZIUTRFRmdRVVVGQytjRkNEZzRwQVpmb0ZGbDhXODhjWFdIRXcKSHdZRFZSMGpCQmd3Rm9BVVVGQytjRkNEZzRwQVpmb0ZGbDhXODhjWFdIRXdEd1lEVlIwVEFRSC9CQVV3QXdFQgovekFOQmdrcWhraUc5dzBCQVFzRkFBT0NBZ0VBeitVQXdxY1hwaGhkM0FKU0RLYnRTa29WMXhEUlBqOEhhdlNZCjlDOEZ0cUpVZEdLN0E5NDZNUE96bHMxSlAyTE5pQnN4b1FTa25YeU4wZEhVRndvNVZhNW4rd3pScmFsQzlqczAKM1lQVDZSSjBmQk8yRUtXbWNuZ2Ewd2lmYVJBVXhHWmY4dnY1b3RHLzY0UzhhMlFCU3VJOEl1a1NpelB1ZGtRTQoyWGRDK25FeGNGKzVKZVRrVEtFeDcxeGl6Q3FUOG1PdlRuMlloZW9qRVJON01PZzNxRkR0bWg0OTRoaEZDYzRoCkxwc3RYR2VDbHFPVEJldzh1WjRuZ0hLQ3Rqc3dBdXczWXZnRU8yNWFIcDJHTkpCek5aYTYzSDZZY2xuL1JFcnUKeklHUTBWME12RUJudldlWXRheCtoV2QzbmRsYk9pS0doSGNIQlBxNnJkUUFJdkpuaHlzNXBzZVVWTUYyU0tLYQpDT1NIczVyenJVbzNONGhpU1gzZUNHNG9TUkp4cEYrQVlRUEJQWXhIVDBYa2dEb212RGJ6WUdvbWx0RkFqdkFmCktXc0pYUk1mcVczNGdPV3QzZlZFaFVUZVZGc0t5YXFDbnkxVDFKUVJ3QmdzSmNKVjhYcDBaK0JOc1V2Y1pDY2EKSlVjSzlEbGUrUk83MktxdlZaeHYzaUc3UW40RW5tWHFuZUpTYXRrbXY4ejJiK29EVFNBNUppMXFSb2VuK216SgovU2NYR2hJaHBIS1ZBczB1Qit5YXc3QkZNQlBibHRlK2N4emVwd3FmdDdhZWtGZTVvcFRrOGUxTXBrcXhCNmF3Cm1XdnRUUFBZVlk3bjVGaEdMUHJZUllENlJ2SzU0NmR1L0lERUlMcUdxRkVkWU5TQ1hMREFpbllKbE43bytTZ1YKa1RTb0RVQT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
  tls.key: ${tls_key} 
EOF

    # Git clone
    git clone ${github_repo}

    # Copy init manifests to init folder
    cp -rv ./kubernetes-gitops/deploy/k8s/01-namespaces ${manifest_location}
    cp -rv ./kubernetes-gitops/deploy/k8s/02-kube-vip ${manifest_location}
    cp -rv ./kubernetes-gitops/deploy/k8s/03-metallb ${manifest_location}
    cp -rv ./kubernetes-gitops/deploy/k8s/04-bitnami ${manifest_location}
    cp -rv ./kubernetes-gitops/deploy/k8s/05-nginx ${manifest_location}
    cp -rv ./kubernetes-gitops/deploy/k8s/06-certificates ${manifest_location}
    cp -rv ./kubernetes-gitops/deploy/k8s/07-csi ${manifest_location}
    cp -rv ./kubernetes-gitops/deploy/k8s/08-harbor ${manifest_location}

    echo -e "\nInstalling k3s master and initializing the cluster...\n" &&
      curl -sfL https://get.k3s.io | K3S_TOKEN=${k3s_token} sh -s - --write-kubeconfig-mode=644 --disable servicelb --disable traefik --tls-san ${k3s_vipip} --cluster-init
  else
    echo -e "\nInstalling k3s master and joining to cluster...\n" &&
      curl -sfL https://get.k3s.io | K3S_TOKEN=${k3s_token} sh -s - --write-kubeconfig-mode=644 --disable servicelb --disable traefik --tls-san ${k3s_vipip} --server=https://${k3s_cluster_init_ip}:6443
  fi
  sleep 15 && echo -e "\nInstalling k3s on $HOSTNAME done.\n" &&
    kubectl get nodes -o wide
else
  # Setup workers
  echo -e "\nInstalling k3s workers and joining to cluster...\n" &&
    curl -sfL https://get.k3s.io | K3S_URL=https://${k3s_cluster_init_ip}:6443 K3S_TOKEN=${k3s_token} sh -
fi
