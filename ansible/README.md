# Ansible

[![Ansible image](https://github.com/x-real-ip/infrastructure/actions/workflows/ansible-image.yaml/badge.svg)](https://github.com/x-real-ip/infrastructure/actions/workflows/ansible-image.yaml)


podman run --rm -it --network host -v $(pwd):/ansible -v ~/.ssh/ansible:/root/.ssh/id_rsa:ro my-ansible ansible-playbook -K --ask-pass --ask-vault-password playbooks/truenas_snapshot-tasks.yaml

podman run --rm -it my-ansible ansible-playbook -K --ask-pass --ask-vault-password playbooks/desktop.yaml


ansible-playbook --ask-vault-password playbooks/truenas_snapshot-tasks.yaml