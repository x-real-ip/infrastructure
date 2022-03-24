# K3s - First steps

Lightweight, easy, fast Kubernetes distribution with a very small footprint
https://k3s.io

## Install VM's and make a template.

1. Install VM's with Ubuntu server.
2. After installation change/add hostname in `/etc/hosts` and `/etc/hostname`
3. # Create hostname and static ip in DHCP server (pfSense)
4. Change/add hostname in `/etc/hosts` and `/etc/hostname`
5. Update

```
sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get distro-upgrade -y
```

3. Install packages.

```
sudo apt-get install qemu-guest-agent curl nfs-common -y
```

4. Create hostname and static ip in DHCP server (pfSense).
5. Create template from this VM.

## Install Master node(s)

SSH into the master node(s)

```
export K3S_KUBECONFIG_MODE="644"

export INSTALL_K3S_EXEC=" --no-deploy servicelb --no-deploy traefik"

curl -sfL https://get.k3s.io | sh -
```

## Save server Token

Grab token from the master node to be able to add worked nodes to it and save it (in a passwordmanager).

```
cat /var/lib/rancher/k3s/server/node-token
```

## Install Worker node(s)

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
echo -n "password123" | base64 -i -
```
