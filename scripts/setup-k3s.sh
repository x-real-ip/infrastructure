#!/bin/bash

# Install k3s and dependencies
# Writtin by Coen Stam.
# github@theautomation.nl
#

manifest_location="/var/lib/rancher/k3s/server/manifests/"
github_k8s_url="https://raw.githubusercontent.com/theautomation/kubernetes-gitops/main/deploy/k8s"

sudo apt update
sudo apt upgrade -y
sudo apt install -y curl wget unzip

# # NFS
# echo "Installing NFS..." &&
#     sudo apt install -y libnfs-utils

# # ISCSI
# echo "Installing ISCSI..." &&
#     sudo apt-get install -y open-iscsi lsscsi sg3-utils multipath-tools scsitools

# sudo tee /etc/multipath.conf <<-'EOF'
# defaults {
#     user_friendly_names yes
#     find_multipaths yes
# }
# EOF

# sudo systemctl enable multipath-tools.service
# sudo service multipath-tools restart
# sudo systemctl enable open-iscsi.service
# sudo service open-iscsi start

# QEMU guest agent
echo "Installing QEMU guest agent..." &&
    sudo apt-get install qemu-guest-agent -y

if [[ $HOSTNAME =~ master ]]; then
    # Setup masters
    if [[ $HOSTNAME = "k3s-master-01" ]]; then
        # Add manifests
        sudo mkdir -p ${manifest_location} &&
            cd ${manifest_location}
        curl -O ${github_k8s_url}/metallb/metallb-manifest.yaml
        curl -O ${github_k8s_url}/nginx-ingress-controller/nginx-ingress-controller-prd-ext-manifest.yaml
        curl -O ${github_k8s_url}/nginx-ingress-controller/nginx-ingress-controller-prd-int-manifest.yaml
        # curl -O ${github_k8s_url}/bitnami/bitnami-manifest.yaml
        # curl -O ${github_k8s_url}/argocd/argocd-manifest.yaml

        echo -e "\nInstalling k3s master and initializing the cluster...\n" &&
            curl -sfL https://get.k3s.io | K3S_TOKEN=${k3s_token} sh -s - --write-kubeconfig-mode=644 --no-deploy servicelb --no-deploy traefik --no-deploy servicelb --cluster-init
    else
        echo -e "\nInstalling k3s master and joining to cluster...\n" &&
            curl -sfL https://get.k3s.io | K3S_TOKEN=${k3s_token} sh -s - --write-kubeconfig-mode=644 --no-deploy servicelb --no-deploy traefik --no-deploy servicelb --server=https://${k3s_cluster_init_ip}:6443
    fi
    sleep 20 && echo "Installing k3s on $HOSTNAME done." &&
        kubectl get nodes
else
    # Setup workers
    echo -e "\nInstalling k3s workers and joining to cluster...\n" &&
        curl -sfL https://get.k3s.io | K3S_URL=https://${k3s_cluster_init_ip}:6443 K3S_TOKEN=${k3s_token} sh -
fi
