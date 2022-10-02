# Kubernetes GitOps

- [Kubernetes GitOps](#kubernetes-gitops)
  - [Gitops hierarchy](#gitops-hierarchy)
  - [Setup](#setup)
    - [Bootstrap K3s cluster](#bootstrap-k3s-cluster)
    - [Local](#local)
      - [Kubectl](#kubectl)
      - [Bitnami Kubeseal](#bitnami-kubeseal)
  - [Kubernetes Cheatsheet](#kubernetes-cheatsheet)
    - [Maintain cluster node](#maintain-cluster-node)
    - [Upgrade K3s](#upgrade-k3s)
  - [Bitnami Sealed Secret](#bitnami-sealed-secret)
  - [Other](#other)
    - [Rsync](#rsync)
    - [ISCSI](#iscsi)
      - [Migration notes:](#migration-notes)
      - [Repair PVC using iSCSI mounts:](#repair-pvc-using-iscsi-mounts)
  - [Node Feature Discovery](#node-feature-discovery)

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

1. Create VM's and install debian on it. For example 3x master 2x worker nodes.
2. SSH into each node en run below commands:

Set hostname
```console 
hostnamectl set-hostname <hostname>
```

Set hostname in ```/etc/hosts```
```console
nano /etc/hosts
```
3. Install CURL
```
apt install curl -y
```

4. Reboot the host machine
5. Assing static ip in firewall/router for the VM's
6. Reboot the host machine's
7. ssh into the k3s nodes and apply below, the tls_key is only needed in the k3s-master-01 VM.

```console
export k3s_token="<k3s_token>"

export k3s_cluster_init_ip="192.168.1.101"

export k3s_vipip="192.168.1.100"

# tls.key base64 encoded string for Bitnami Sealed Secret
export tls_key="<tls.key>"

curl -sfL https://raw.githubusercontent.com/theautomation/kubernetes-gitops/main/scripts/setup-k3s.sh | bash -
```
7. After applying the above command on each node k3s is setup.

### Local

#### Kubectl
1. Install kubectl on your local machine.
Read the [following page](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) to know how to install kubectl on Linux.

2. Copy the k3s config file from the master node to your local machine

```console
mkdir -p ~/.kube/ \
&& scp coen@k3s-master-01.lan:/etc/rancher/k3s/k3s.yaml ~/.kube/config \
&& sed -i 's/127.0.0.1/192.168.1.100/g' ~/.kube/config
```

#### Bitnami Kubeseal
Install Kubeseal locally to use Bitnami sealed serets in k8s.
```console
sudo wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/kubeseal-0.18.0-linux-amd64.tar.gz

sudo tar xzvf kubeseal-0.18.0-linux-amd64.tar.gz

sudo install -m 755 kubeseal /usr/local/bin/kubeseal
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

Copy to or from pod
```console
kubectl cp <namespace>/<pod>:/tmp/foo /tmp/bar
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

### Upgrade K3s

1- To use the image with the system-upgrade-controller, you have first to run the controller either directly or deploy it on the k3s cluster:

```
kubectl apply -f https://raw.githubusercontent.com/rancher/system-upgrade-controller/master/manifests/system-upgrade-controller.yaml
```

You should see the upgrade controller starting in `system-upgrade` namespace.

2- Label the nodes you want to upgrade with the right label:
```
kubectl label node <node-name> k3s-upgrade=true
```

3- Run the upgrade plan in the k3s cluster

```
---
apiVersion: upgrade.cattle.io/v1
kind: Plan
metadata:
  name: k3s-latest
  namespace: system-upgrade
spec:
  concurrency: 1
  version: v1.17.2-k3s1
  nodeSelector:
    matchExpressions:
      - {key: k3s-upgrade, operator: Exists}
  serviceAccountName: system-upgrade
  drain:
    force: true
  upgrade:
    image: rancher/k3s-upgrade
``` 

The upgrade controller should watch for this plan and execute the upgrade on the labeled nodes. For more information about system-upgrade-controller and plan options please visit [system-upgrade-controller](https://github.com/rancher/system-upgrade-controller) official repo.

## Bitnami Sealed Secret

Create TLS (unencrypted) secret
```
kubectl create secret tls cloudflare-tls --key origin-ca.pk --cert origin-ca.crt --dry-run=client -o yaml > cloudflare-tls.yaml
```

Encrypt secret with custom public certificate.
```console
kubeseal --cert "./sealed-secret-tls-2.crt" --format=yaml < secret.yaml > sealed-secret.yaml
```

Add sealed secret to configfile secret
```console
    echo -n <mypassword_value> | kubectl create secret generic <secretname> --dry-run=client --from-file=<password_key>=/dev/stdin -o json | kubeseal --cert ./sealed-secret-tls-2.crt -o yaml \
    -n democratic-csi --merge-into <secret>.yaml
```

Raw sealed secret

`strict` scope (default):

```console
echo -n foo | kubeseal --raw --from-file=/dev/stdin --namespace bar --name mysecret
AgBChHUWLMx...
```

`namespace-wide` scope:

```console
echo -n foo | kubeseal --cert ./sealed-secret-tls-2.crt --raw --from-file=/dev/stdin --namespace bar --scope namespace-wide
AgAbbFNkM54...
```

`cluster-wide` scope:

```console
echo -n foo | kubeseal --cert ./sealed-secret-tls-2.crt --raw --from-file=/dev/stdin --scope cluster-wide
AgAjLKpIYV+...
```

Include the `sealedsecrets.bitnami.com/namespace-wide` annotation in the `SealedSecret`
```yaml
metadata:
  annotations:
    sealedsecrets.bitnami.com/namespace-wide: "true"
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

#### Migration notes:

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

#### Repair PVC using iSCSI mounts:

1. SSH into one of the nodes in the cluster and start discovery 
    ```console
    sudo iscsiadm -m discovery -t st -p storage-server.lan
    ```
2. Login to target 
    ```console
    sudo iscsiadm --mode node --targetname iqn.2005-10.org.freenas.ctl:<disk-name> --portal storage-server.lan --login
    ``` 
3. See the device using ```lsblk```. In the following steps, assume sdd is the device name.
4. Create a local mount point & mount to replay logfile ```sudo mkdir -vp /mnt/data-0 && sudo mount /dev/sdd /mnt/data-0/```
5. Unmount the device ```sudo umount /mnt/data-0/```
6. Run check / ncheck ```sudo xfs_repair -n /dev/sdd; sudo xfs_ncheck /dev/sdd``` If filesystem corruption was corrected due to replay of the logfile, the xfs_ncheck should produce a list of nodes and pathnames, instead of the errorlog.
7.  If needed run xfs repair ```sudo xfs_repair /dev/sdd```
8.  Logout from target 
    ```console
    sudo iscsiadm --mode node --targetname iqn.2005-10.org.freenas.ctl:<disk-name> --portal storage-server.lan --logout
    ```
9.  Volumes are now ready to be mounted as PVCs.


## Node Feature Discovery
Show node lables
```console
kubectl get no -o json | jq .items[].metadata.labels
```