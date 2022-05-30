#!/bin/bash
#
# Install k3s and dependencies
# Writtin by Coen Stam.
# github@theautomation.nl
#

set -e

# openSSH
echo "Installing OpenSSH..." && \
sudo apt install openssh-server openssh-client

# NFS
echo "Installing NFS..." && \
sudo apt install -y libnfs-utils

# ISCSI
echo "Installing ISCSI..." && \
sudo apt-get install -y open-iscsi lsscsi sg3-utils multipath-tools scsitools

sudo tee /etc/multipath.conf <<-'EOF'
defaults {
    user_friendly_names yes
    find_multipaths yes
}
EOF

# QEMU guest agent
echo "Installing QEMU guest agent..." && \
sudo apt-get install qemu-guest-agent -y

# K3s worker
echo "Installing k3s worker and joining to cluster..." && \
curl -sfL https://get.k3s.io | K3S_URL=https://${k3s_cluster_init_ip}:6443 K3S_TOKEN=${k3s_token} sh -

echo "Script done..."