#!/bin/bash

# Configure Debian desktop and packages.
# Writtin by Coen Stam.
# github@theautomation.nl
#

# Upgrade system
apt-get update \
&& apt-get upgrade -y

# Install packages
apt-get install -y \
code \
git \
curl \
cifs-utils \
nfs-common

# Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
&& chmod 700 get_helm.sh \
&& ./get_helm.sh