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