#!/bin/bash

playbook="local.yaml"

export ANSIBLE_CONFIG="${PWD}/../../ansible.cfg"

ansible-playbook ../../playbooks/${playbook} -kK
