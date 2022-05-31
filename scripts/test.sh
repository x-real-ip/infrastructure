#!/bin/bash
#
# Install k3s dependencies
# Writtin by Coen Stam.
# github@theautomation.nl
#

echo "test"

curl -O ${github_k8s_url}/bitnami/bitnami-manifest.yaml

sudo apt update > /dev/null
sudo apt upgrade -y > /dev/null