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

1. Install Mysql
2. Create user for K3s
3. From the Mysql installation download `cert.crt`, `cert.key` and `ca.pem` from `/etc/mysql/certificates/` en put these into the master nodes in the same directory `/etc/mysql/certificates/`

## Install k3s on Master node(s)

SSH into the master node(s)

```
curl -sfL https://get.k3s.io | \
  INSTALL_K3S_EXEC=" --no-deploy servicelb --no-deploy traefik" \
  K3S_DATASTORE_ENDPOINT="mysql://k3s:<PASSWORD>@tcp(mysql.lan:3306)/k3s" \
  K3S_DATASTORE_CERTFILE="/etc/mysql/certificates/cert.crt" \
  K3S_DATASTORE_KEYFILE="/etc/mysql/certificates/cert.key" \
  K3S_DATASTORE_CAFILE="/etc/mysql/certificates/ca.pem" \
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
export K3S_KUBECONFIG_MODE="644"
export K3S_URL="https://k3s-master-01.lan:6443"
export K3S_TOKEN="<TOKEN HERE>"
curl -sfL https://get.k3s.io | sh -
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
