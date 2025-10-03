[![Continuous integration](https://github.com/x-real-ip/ansible/actions/workflows/ci.yaml/badge.svg)](https://github.com/x-real-ip/ansible/actions/workflows/ci.yaml)
![GitHub repo size](https://img.shields.io/github/repo-size/x-real-ip/ansible?logo=Github)
![GitHub commit activity](https://img.shields.io/github/commit-activity/y/x-real-ip/ansible?logo=github)
![GitHub last commit (branch)](https://img.shields.io/github/last-commit/x-real-ip/ansible/main?logo=github)


podman run --rm -it --network host -v $(pwd):/ansible my-ansible ansible-playbook -K --ask-pass --ask-vault-password playbooks/desktop.yaml

podman run --rm -it my-ansible ansible-playbook -K --ask-pass --ask-vault-password playbooks/desktop.yaml