#!/bin/bash

playbook="k3s_install.yaml"

export ANSIBLE_CONFIG="${PWD}/../../ansible.cfg"

ansible-playbook ../../playbooks/${playbook} -kK
