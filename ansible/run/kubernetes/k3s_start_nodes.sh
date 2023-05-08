#!/bin/bash

playbook="k3s_start_all_nodes.yaml"

export ANSIBLE_CONFIG="${PWD}/../../ansible.cfg"

ansible-playbook ../../playbooks/${playbook} -kK
