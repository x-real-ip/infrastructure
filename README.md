# K3s - First steps

Lightweight, easy, fast Kubernetes distribution with a very small footprint
https://k3s.io

## Prepare VM's

1. Install VM's with Ubuntu server.
2. After installation change/add hostname in `/etc/hosts` and `/etc/hostname`
3. Create hostname and static ip in DHCP server (pfSense)
4. Update

```
sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y
```

6. Install packages.

```
sudo apt-get install qemu-guest-agent curl nfs-common -y
```

8. Create template from this VM.

## Setup external Database

1. Install Postgress container
2. Create user and database for K3s

## Install k3s on Master node(s)

SSH into the master node(s)
```
curl -sfL https://get.k3s.io | \
INSTALL_K3S_EXEC=" --no-deploy servicelb --no-deploy traefik" \
K3S_KUBECONFIG_MODE="644" \
K3S_DATASTORE_ENDPOINT='postgres://k3s:<PASSWORD HERE>@k3s-postgresql.lan:5432/k3s' \
K3S_TOKEN="<TOKEN HERE>" \
sh -s 
```

## Save server Token

Grab token from the master node to be able to add worker nodes to it and save it (in a passwordmanager).

```
cat /var/lib/rancher/k3s/server/node-token
```

## Install k3s on Worker node(s)

Install k3s on the worker node and add it to our cluster. SSH into the worker node(s)

```
curl -sfL https://get.k3s.io | \
K3S_URL="https://k3s-master-01.lan:6443" \
K3S_TOKEN="<TOKEN HERE>"
sh -s
```

## Connect remotely to the cluster

Install kubectl on your local machine
Read the [following page](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) to know how to install kubectl on Linux.

Copy the k3s config file from the master node to your local machine

```
mkdir ~/.kube/

scp coen@k3s-master-01.lan:/etc/rancher/k3s/k3s.yaml ~/.kube/config

export KUBECONFIG=~/.kube/config

```

Test

```
kubectl get nodes
```

## Cheatsheet

### create secret base64 encode

```bash
echo -n "<PASSWORD>" | base64 -i -
```
