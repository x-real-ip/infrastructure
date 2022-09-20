#!/bin/bash

# Install k3s and dependencies
# Writtin by Coen Stam.
# github@theautomation.nl
#

manifest_location="/var/lib/rancher/k3s/server/manifests/"
github_k8s_url="https://raw.githubusercontent.com/theautomation/kubernetes-gitops/main/deploy/k8s"

# Update and install packages
sudo apt update
sudo apt upgrade -y
sudo apt install -y curl wget unzip git

# ISCSI
echo -e "\nInstalling ISCSI...\n"
sudo apt-get install -y open-iscsi lsscsi sg3-utils multipath-tools scsitools

sudo tee /etc/multipath.conf <<-'EOF'
defaults {
    user_friendly_names yes
    find_multipaths yes
}
EOF

sudo systemctl enable multipath-tools.service
sudo service multipath-tools restart
sudo systemctl enable open-iscsi.service
sudo service open-iscsi start

# QEMU guest agent
echo -e "\nInstalling QEMU guest agent...\n" &&
    sudo apt-get install qemu-guest-agent -y

if [[ $HOSTNAME =~ master ]]; then
    # Setup masters
    if [[ $HOSTNAME = "k3s-master-01" ]]; then
        # Add manifests
        sudo mkdir -p ${manifest_location} &&
            cd ${manifest_location}
        sudo curl -O ${github_k8s_url}/init/01-kube-vip.yaml
        sudo curl -O ${github_k8s_url}/init/02-namespaces.yaml
        sudo curl -O ${github_k8s_url}/init/03-metallb.yaml
        sudo curl -O ${github_k8s_url}/init/04-nginx-ingress-controller-prd-ext-manifest.yaml
        sudo curl -O ${github_k8s_url}/init/04-nginx-ingress-controller-prd-int-manifest.yaml
        sudo curl -O ${github_k8s_url}/init/05-bitnami-manifest.yaml

        echo -e "\nInstalling k3s master and initializing the cluster...\n" &&
            curl -sfL https://get.k3s.io | K3S_TOKEN=${k3s_token} sh -s - --write-kubeconfig-mode=644 --no-deploy servicelb --no-deploy traefik --tls-san ${k3s_vipip} --no-deploy servicelb --cluster-init
    else
        echo -e "\nInstalling k3s master and joining to cluster...\n" &&
            curl -sfL https://get.k3s.io | K3S_TOKEN=${k3s_token} sh -s - --write-kubeconfig-mode=644 --no-deploy servicelb --no-deploy traefik --tls-san ${k3s_vipip} --no-deploy servicelb --server=https://${k3s_cluster_init_ip}:6443
    fi
    sleep 20 && echo -e "\nInstalling k3s on $HOSTNAME done.\n" &&
        kubectl get nodes -o wide
else
    # Setup workers
    echo -e "\nInstalling k3s workers and joining to cluster...\n" &&
        curl -sfL https://get.k3s.io | K3S_URL=https://${k3s_cluster_init_ip}:6443 K3S_TOKEN=${k3s_token} sh -
fi
