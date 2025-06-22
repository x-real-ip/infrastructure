| Playbook | Command | Comment |
|----------|----------|----------|
| non-root-user    | ansible-playbook -k --ask-vault-password non-root-user.yaml   |   Add a non root user   |
| desktop    | ansible-playbook -K --ask-vault-password desktop.yaml   |   Set the Debian desktop desired state   |
| truenas-shares    | ansible-playbook truenas-shares.yaml   |   Configure all NFS and ISCSI shares on the truenas hosts   |
| truenas_switch-master    | ansible-playbook --ask-vault-password truenas_switch-master.yaml   | Switch the master from A to B or the otherway around   |
| shelly_update-firmware    | ansible-playbook shelly_update-firmware.yaml   |   Update and set desired state of all Shelly devices   |
| k3s_rolling-update-nodes    | ansible-playbook --ask-vault-password k3s_rolling-update-nodes.yaml   |   Update the os packages on all k3s nodes   |
| k3s_install_cluster_minimal    | ansible-playbook --ask-vault-password k3s_install_cluster_minimal.yaml   |  Install or update k3s to the latest version all k3s nodes   |


