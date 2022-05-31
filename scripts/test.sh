#!/bin/bash

echo "test"

curl -O ${github_k8s_url}/bitnami/bitnami-manifest.yaml

sudo apt update > /dev/null
sudo apt upgrade -y > /dev/null

echo K3S_TOKEN=${k3s_token}