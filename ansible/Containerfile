FROM docker.io/python:3.12-slim

ENV ANSIBLE_FORCE_COLOR=1 \
    ANSIBLE_STDOUT_CALLBACK=default

COPY requirements.txt .

RUN apt -y update && \
    apt -y install sshpass && \
    python -m pip install --upgrade pip && \
    python -m pip install -r requirements.txt && \
    apt -y autoremove && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /ansible

COPY . /ansible

RUN ansible-galaxy install -r requirements.yaml
