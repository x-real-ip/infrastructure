#!/bin/bash

playbook="k3s_rolling_update_nodes.yaml"

export ANSIBLE_CONFIG="${PWD}/../../ansible.cfg"

ansible-playbook ../../playbooks/${playbook} -kK
