#!/bin/bash

echo "test"

curl -O ${github_k8s_url}/bitnami/bitnami-manifest.yaml

sudo apt update
sudo apt upgrade -y

echo K3S_TOKEN=${k3s_token}