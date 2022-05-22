# Setup

## Hardware hierarchy

```
├───────── hypervisor (proxmox-ve)
│  ├────── kubernetes (k3s) master nodes
│    ├──── control plane
│    ├──── etcd
│  ├────── kubernetes (k3s) worker nodes
│    ├──── pods
|    ├──── ...
│  │────── pfSense (firewall)
```
```
├─── storage-server (truenas)
```

## Installation

1. Need to have a Proxmox server installed for k8s master and worker nodes as VM's.
2. Setup API in proxmox to use terraform.
3. Install Terraform locally to apply terraform plan to proxmox.
4. Install Kubeseal locally to use Bitnami sealed serets in k8s.
```console
   wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.17.5/kubeseal-linux-amd64 -O kubeseal
   sudo install -m 755 kubeseal /usr/local/bin/kubeseal
```

5. Add A record in pfSense to bind a domainname for redirecting internal traffic into k8s private ingress controller.
```
local-zone: "k8s.lan" redirect
local-data: "k8s.lan 86400 IN A 192.168.1.240"
```
5. Apply terraform plan to proxmox

6. Install kubectl on your local machine.
   Read the [following page](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) to know how to install kubectl on Linux.

7. Copy the k3s config file from the master node to your local machine

```console
mkdir -p ~/.kube/ \
&& scp coen@192.168.1.11:/etc/rancher/k3s/k3s.yaml ~/.kube/config \
&& sed -i 's/127.0.0.1/192.168.1.11/g' ~/.kube/config```
```

8. Set right ipaddress to Master node in the config file

Test if kubeconfig is working

```console
kubectl get nodes
```

9. Install tekton cli 
```console
curl -LO https://github.com/tektoncd/cli/releases/download/v0.23.1/tkn_0.23.1_Linux_x86_64.tar.gz
sudo tar xvzf tkn_0.23.1_Linux_x86_64.tar.gz -C /usr/local/bin/ tkn
``` 

# Kubernetes Cheatsheet

### Convert to BASE64
```console
echo -n '<value>' | base64
```

### Decode a secret with config file data
```console
kubectl get secret <secret_name> -o jsonpath='{.data}' -n <namespace>
```

### Restart Pod
```batch
kubectl rollout restart deployment <deployment name> -n <namespace>
```

## Change PV reclaim policy
```console
kubectl patch pv <pv-name> -p "{\"spec\":{\"persistentVolumeReclaimPolicy\":\"Retain\"}}"
```

### Reuse PV in PVC
1. Remove the claimRef in the PV this will set the PV status from ```Released``` to ```Available```
```console
kubectl patch pv <pv_name> -p '{"spec":{"claimRef": null}}'
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

### Maintain node

Use kubectl drain to gracefully terminate all pods on the node while marking the node as unschedulable
```console
kubectl drain <nodename>
```

Make the node schedulable again
```console
kubectl uncordon <nodename>
```


# Bitnami Sealed secret

### Create TLS (unencrypted) secret
```
kubectl create secret tls cloudflare-tls --key origin-ca.pk --cert origin-ca.crt --dry-run=client -o yaml > cloudflare-tls.yaml
```

### Encrypt secret with custom public certificate.
```console
kubeseal --cert "./kubernetes-gitops/certs/sealed-secret-tls.crt" --format=yaml < <secret>.yaml > sealed-<secret>.yaml
```

### Add sealed secret to configfile secret
```console
    echo -n <mypassword_key> | kubectl create secret generic <secretname> --dry-run=client --from-file=<password_value>=/dev/stdin -o json | kubeseal --cert ./sealed-secret-tls.crt -o yaml \
    -n democratic-csi --merge-into <secret>.yaml
```

### Raw sealed secret

`strict` scope (default):

```console
$ echo -n foo | kubeseal --raw --from-file=/dev/stdin --namespace bar --name mysecret
AgBChHUWLMx...
```

`namespace-wide` scope:

```console
$ echo -n foo | kubeseal --raw --from-file=/dev/stdin --namespace bar --scope namespace-wide
AgAbbFNkM54...
```
Include the `sealedsecrets.bitnami.com/namespace-wide` annotation in the `SealedSecret`
```yaml
metadata:
  annotations:
    sealedsecrets.bitnami.com/namespace-wide: "true"
```

`cluster-wide` scope:

```console
$ echo -n foo | kubeseal --raw --from-file=/dev/stdin --scope cluster-wide
AgAjLKpIYV+...
```
Include the `sealedsecrets.bitnami.com/cluster-wide` annotation in the `SealedSecret`
```yaml
metadata:
  annotations:
    sealedsecrets.bitnami.com/cluster-wide: "true"
```


[Github](https://github.com/bitnami-labs/sealed-secrets)

[AWS Bitnami tutorial](https://aws.amazon.com/blogs/opensource/managing-secrets-deployment-in-kubernetes-using-sealed-secrets/)

[Blogpost Tutorial](https://itsmetommy.com/2020/06/26/kubernetes-sealed-secrets/)


# ArgoCD

Get admin password after deploy
```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```