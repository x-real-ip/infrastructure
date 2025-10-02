podman run --rm -it --network host -v $(pwd):/ansible my-ansible ansible-playbook -K --ask-pass --ask-vault-password playbooks/desktop.yaml

podman run --rm -it my-ansible ansible-playbook -K --ask-pass --ask-vault-password playbooks/desktop.yaml