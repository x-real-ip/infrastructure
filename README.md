# Rancher's k3s - First steps

Lightweight, easy, fast Kubernetes distribution with a very small footprint
https://k3s.io

## Install VM

1. Change/add hostname in `/etc/hosts` and `/etc/hostname`
2. Create hostname and static ip in DHCP server (pfSense)

## Install Master

```
curl -sfL https://get.k3s.io | sh -s - server --no-deploy traefik --disable servicelb --write-kubeconfig-mode 644
```

## Install Worker

Grab token from the master node to be able to add worked nodes to it and save it into a passwordmanager.

```
cat /var/lib/rancher/k3s/server/node-token
```

Install k3s on the worker node and add it to our cluster:

```
curl -sfL https://get.k3s.io | K3S_URL=https://k3s-master-01.lan:6443 K3S_TOKEN=<TOKEN> sh -
```

## Install nginx ingress controller

Website: https://kubernetes.github.io/ingress-nginx/

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.47.0/deploy/static/provider/cloud/deploy.yaml
```

## Additional information

You can change the settings of k3s by changing the service settings e.g. with:

```
nano /etc/systemd/system/k3s.service
```

Make sure to restart the service afterwards:

```
systemctl restart k3s
```

In many cases you can just run the installer with different variables again and it will configure your cluster accordingly without deleting it in the first place.
