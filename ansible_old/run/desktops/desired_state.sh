#!/bin/bash

playbook="desktops_desired_state.yaml"

export ANSIBLE_CONFIG="${PWD}/../../ansible.cfg"

ansible-playbook ../../playbooks/${playbook} -kK
