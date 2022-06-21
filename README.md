# Kubernetes Gitops

- [Kubernetes Gitops](#kubernetes-gitops)
  - [Gitops hierarchy](#gitops-hierarchy)
  - [Setup](#setup)
    - [Bootstrap K3s cluster](#bootstrap-k3s-cluster)
    - [Local](#local)
      - [Kubectl](#kubectl)
      - [Bitnami Kubeseal](#bitnami-kubeseal)
      - [ArgoCD CLI](#argocd-cli)
      - [Tekton CLI](#tekton-cli)
  - [Kubernetes Cheatsheet](#kubernetes-cheatsheet)
    - [Maintain cluster node](#maintain-cluster-node)
  - [Bitnami Sealed Secret](#bitnami-sealed-secret)
  - [ArgoCD](#argocd)
  - [Other](#other)
    - [Rsync](#rsync)
    - [ISCSI](#iscsi)

## Gitops hierarchy

```
├───────── deploy
│  ├────── argocd             # Argocd applications
│  ├────── k8s                # Bootstrap cluster k8s manifests
│  ├────── tekton             # Tekton resources for CI piplines
│  ├────── terraform          # Terraform plan to apply k8s VM cluster in Proxmox
```

## Setup

### Bootstrap K3s cluster

1. Create VM's and install ubuntu server on it. For example 3x master 2x worker nodes.
2. SSH into each node en run below commands:

```console
export k3s_token="<k3s_token>"

export k3s_cluster_init_ip="<ip_of_master-01>"

export k3s_vipip="192.168.1.10"

curl -sfL https://raw.githubusercontent.com/theautomation/kubernetes-gitops/main/scripts/setup-k3s.sh | bash -
```

### Local

#### Kubectl
1. Install kubectl on your local machine.
Read the [following page](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) to know how to install kubectl on Linux.

2. Copy the k3s config file from the master node to your local machine

```console
mkdir -p ~/.kube/ \
&& scp coen@k3s-master-01.lan:/etc/rancher/k3s/k3s.yaml ~/.kube/config \
&& sed -i 's/127.0.0.1/k3s-master-01.lan/g' ~/.kube/config
```

#### Bitnami Kubeseal
Install Kubeseal locally to use Bitnami sealed serets in k8s.
```console
sudo wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/kubeseal-0.18.0-linux-amd64.tar.gz

sudo tar xzvf kubeseal-0.18.0-linux-amd64.tar.gz

sudo install -m 755 kubeseal /usr/local/bin/kubeseal
```

#### ArgoCD CLI
Intall ArgoCD cli
```console
sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64

sudo chmod +x /usr/local/bin/argocd
```

#### Tekton CLI
Install tekton cli 
```console
curl -LO https://github.com/tektoncd/cli/releases/download/v0.23.1/tkn_0.23.1_Linux_x86_64.tar.gz

sudo tar xvzf tkn_0.23.1_Linux_x86_64.tar.gz -C /usr/local/bin/ tkn
```

## Kubernetes Cheatsheet

Convert to BASE64
```console
echo -n '<value>' | base64
```

Decode a secret with config file data
```console
kubectl get secret <secret_name> -o jsonpath='{.data}' -n <namespace>
```

Restart Pod
```console
kubectl rollout restart deployment <deployment name> -n <namespace>
```

Change PV reclaim policy
```console
kubectl patch pv <pv-name> -p "{\"spec\":{\"persistentVolumeReclaimPolicy\":\"Retain\"}}"
```

Shell into pod
```console
kubectl exec -it <pod_name> -- /bin/bash
```

Reuse PV in PVC
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

### Maintain cluster node

Use kubectl drain to gracefully terminate all pods on the node while marking the node as unschedulable
```console
kubectl drain --ignore-daemonsets --delete-emptydir-data <nodename>
```

To update node with k3s script [See bootstrap k3s](#bootstrap-k3s-cluster)

Make the node schedulable again
```console
kubectl uncordon <nodename>
```

## Bitnami Sealed Secret

Create TLS (unencrypted) secret
```
kubectl create secret tls cloudflare-tls --key origin-ca.pk --cert origin-ca.crt --dry-run=client -o yaml > cloudflare-tls.yaml
```

Encrypt secret with custom public certificate.
```console
kubeseal --cert "./kubernetes-gitops/certs/sealed-secret-tls.crt" --format=yaml < <secret>.yaml > sealed-<secret>.yaml
```

Add sealed secret to configfile secret
```console
    echo -n <mypassword_key> | kubectl create secret generic <secretname> --dry-run=client --from-file=<password_value>=/dev/stdin -o json | kubeseal --cert ./sealed-secret-tls.crt -o yaml \
    -n democratic-csi --merge-into <secret>.yaml
```

Raw sealed secret

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


## ArgoCD

Use ArgoCD CLI
The end-users need Kubernetes access to manage Argo CD. The argocd CLI has to be configured using the following commands:

change current kube context to argocd namespace
```console
kubectl config set-context --current --namespace=devops
```

Login to ArgoCD directly to Kubernetes
```console
argocd login --core
```

Make WebUI available
```console
argocd admin dashboard
```

## Other

Add A record in pfSense to bind a domainname for redirecting internal traffic into k8s private ingress controller.
```
local-zone: "k8s.lan" redirect
local-data: "k8s.lan 86400 IN A 192.168.1.240"
```

### Rsync
rsync exact copy
```console
sudo rsync -axHAWXS --numeric-ids --info=progress2 /mnt/sourcePart/ /mnt/destPart
```

### ISCSI

Discovering targets in iSCSI server
```console
sudo iscsiadm --mode discovery -t sendtargets --portal storage-server.lan
```

Mount disk
```console
sudo iscsiadm --mode node --targetname iqn.2005-10.org.freenas.ctl:<disk-name> --portal storage-server.lan --login
```

Unmount disk
```console
sudo iscsiadm --mode node --targetname iqn.2005-10.org.freenas.ctl:<disk-name> --portal storage-server.lan -u
```

Migration notes:

1. create iscsi zvol
2. make iscsi share
3. make pv
4. make pvc
5. apply k8s deployment (to let it write data to zvol)
6. delete k8s deployment
7. mount old iscsi driver
8. rsync to temporary folder
9. mount new drive
10. rsync old files to new drive