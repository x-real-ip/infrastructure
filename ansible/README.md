| Playbook | Command |
|----------|----------|
| non-root-user    | ansible-playbook -k --ask-vault-password non-root-user.yaml   |
| desktop    | ansible-playbook -K --ask-vault-password desktop.yaml   |
| truenas-shares    | ansible-playbook truenas-shares.yaml   |
| truenas_switch-master    | ansible-playbook --ask-vault-password truenas_switch-master.yaml   |
| shelly_update-firmware    | ansible-playbook shelly_update-firmware.yaml   |