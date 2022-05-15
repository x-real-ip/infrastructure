# Setup

## Hardware hierarchy

```
├───────── hypervisor (proxmox-ve)
│  ├────── kubernetes (k3s) master nodes
│    ├──── control plane
│    ├──── etcd
│  ├────── kubernetes (k3s) worker nodes
│    ├──── containers
│  │────── pfSense (firewall)
```
```
├─── storage-server (truenas)
```

1. Need to have a Proxmox server installed for k8s master and worker nodes as VM's.
2. Setup API in proxmox to use terraform.
3. Install Terraform locally to apply terraform plan to proxmox.
4. Install Kubeseal locally to use Bitnami sealed serets in k8s.
```bash
   wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.17.5/kubeseal-linux-amd64 -O kubeseal
   sudo install -m 755 kubeseal /usr/local/bin/kubeseal
```
5. Add A record in pfSense
Add A record in pfSense to bind a domainname for redirecting internal traffic into k3s private ingress controller.
```
local-zone: "k8s.lan" redirect
local-data: "k8s.lan 86400 IN A 192.168.1.240"
```
5. Apply terraform plan to proxmox

## Connect remotely to the cluster

1. Install kubectl on your local machine.
   Read the [following page](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) to know how to install kubectl on Linux.

2. Copy the k3s config file from the master node to your local machine

```bash
mkdir -p ~/.kube/ \
&& scp coen@192.168.1.11:/etc/rancher/k3s/k3s.yaml ~/.kube/config \
&& sed -i 's/127.0.0.1/192.168.1.11/g' ~/.kube/config```
```

3. Set right ipaddress to Master node in the config file

Test

```
kubectl get nodes
```

# Kubernetes Cheatsheet

### Convert to BASE64
```batch
echo -n '<value>' | base64
```

### Restart Pod
```batch
kubectl rollout restart deployment <deployment name> -n <namespace>
```

### Reuse PV in PVC
1. Remove the claimRef in the PV this will set the PV status from ```Released``` to ```Available```
```
kubectl patch pv <pv name> -p '{"spec":{"claimRef": null}}'
```
2. Add ```volumeName``` in PVC
```yaml
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pvc-iscsi-home-assistant-data
  namespace: home-automation
  labels:
    app: home-assistant
  annotations:
    volume.beta.kubernetes.io/storage-class: "freenas-iscsi-csi"
spec:
  storageClassName: freenas-iscsi-csi
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  volumeName: pvc-iscsi-home-assistant-data
```

# Bitnami Sealed secret


1. Create TLS secret
```
kubectl create secret tls cloudflare-tls --key origin-ca.pk --cert origin-ca.crt --dry-run=client -o yaml > cloudflare-tls.yaml
```

2. Encrypt secret
```
kubeseal --format=yaml < cloudflare-tls.yaml > sealed-cloudflare-tls.yaml
```

[AWS Bitnami tutorial](https://aws.amazon.com/blogs/opensource/managing-secrets-deployment-in-kubernetes-using-sealed-secrets/)

[Blogpost Tutorial](https://itsmetommy.com/2020/06/26/kubernetes-sealed-secrets/)
