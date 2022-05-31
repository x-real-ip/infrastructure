#!/bin/bash



manifest_location="/var/lib/rancher/k3s/server/manifests/"
github_k8s_url="https://raw.githubusercontent.com/theautomation/kubernetes-gitops/main/deploy/k8s"


echo "test"

curl -O ${github_k8s_url}/bitnami/bitnami-manifest.yaml

sudo apt update
sudo apt upgrade -y

echo "K3S_TOKEN=${k3s_token}"