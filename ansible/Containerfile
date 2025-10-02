FROM docker.io/python:3.12-slim

ENV ANSIBLE_FORCE_COLOR=1 \
    ANSIBLE_STDOUT_CALLBACK=default

# Install system dependencies
RUN apt-get update && apt-get install -y \
    sshpass \
    git \
    util-linux \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN python3 -m pip install --upgrade pip

# Install Python requirements
COPY requirements.txt .
RUN python3 -m pip install -r requirements.txt

WORKDIR /ansible

COPY . /ansible
COPY ansible.cfg /etc/ansible/ansible.cfg

# Install Ansible collections
RUN ansible-galaxy install -r requirements.yaml
