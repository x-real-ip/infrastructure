# infrastructure

- [infrastructure](#infrastructure)
  - [Kubernetes](#kubernetes)
    - [Setting up VM hosts on Proxmox](#setting-up-vm-hosts-on-proxmox)
    - [Install k3s](#install-k3s)
    - [Local initialization and setup](#local-initialization-and-setup)
      - [Kubectl](#kubectl)
      - [Bitnami Kubeseal](#bitnami-kubeseal)
    - [Kubernetes Cheatsheet](#kubernetes-cheatsheet)
    - [Bitnami Sealed Secret](#bitnami-sealed-secret)
    - [Network](#network)
    - [Node Feature Discovery](#node-feature-discovery)
  - [Rsync](#rsync)
  - [ISCSI](#iscsi)
    - [Repair iSCSI share](#repair-iscsi-share)
  - [TrueNAS](#truenas)
    - [Rename volume](#rename-volume)

## Kubernetes

### Setting up VM hosts on Proxmox

1. Create VM from template and bootup.
2. Set static ip for the VM in the DHCP server.
3. Login to the VM and set hostname.
   ```console
   hostnamectl set-hostname <hostname>
   ```
4. Reboot.
5. Set this hostname in the ansible inventory hosts.ini file.

### Install k3s

1. Run Ansible playbook `k3s-prerequisites` to initialize the k3s master and optional worker nodes.
2. 

3.  Run the Ansible `k3s_install` playbook with `./ansible/run/kubernetes/k3s_install.sh`. This Ansible playbook will install K3s and all primary infrastructure applications like Metallb loadbalancer, NGINX ingress controller, Bitnami Sealed Secrets, Democratic-CSI.
4.  Run `k3s_apps` playbook with `./ansible/run/kubernetes/k3s_apps.sh` to install secondary applications to the k3s cluster (optional).

### Local initialization and setup

Flush dns cache, needed when the same hostnames are used in previous machines (optional).

```console
resolvectl flush-caches
```

#### Kubectl

Install kubectl on your local machine. Read the [following page](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) to know how to install kubectl on Linux.

#### Bitnami Kubeseal

Install Kubeseal locally to use Bitnami sealed serets in k8s.

```console
sudo wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.19.1/kubeseal-0.19.1-linux-amd64.tar.gz

sudo tar xzvf kubeseal-0.19.1-linux-amd64.tar.gz

sudo install -m 755 kubeseal /usr/local/bin/kubeseal
```

### Kubernetes Cheatsheet

Drain and terminate all pods gracefully on the node while marking the node as unschedulable

```console
kubectl drain --ignore-daemonsets --delete-emptydir-data <nodename>
```

Make the node unschedulable

```console
kubectl cordon <nodename>
```

Make the node schedulable

```console
kubectl uncordon <nodename>
```

Convert to BASE64

```console
echo -n '<value>' | base64
```

Decode a secret with config file data

```console
kubectl get secret <secret_name> -o jsonpath='{.data}' -n <namespace>
```

Create secret from file

```console
kubectl create secret generic <secret name> --from-file=<secret filelocation> --dry-run=client  --output=yaml > secrets.yaml
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

1. Remove the claimRef in the PV this will set the PV status from `Released` to `Available`

```console
kubectl patch pv <pv_name> -p '{"spec":{"claimRef": null}}'
```

2. Add `volumeName` in PVC

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

### Bitnami Sealed Secret

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

### Network

Add A record in pfSense to bind specific domain (`*.k8s.lan`) for redirecting internal traffic into k8s private ingress controller.

```
local-zone: "k8s.lan" redirect
local-data: "k8s.lan 86400 IN A 192.168.1.240"
```

### Node Feature Discovery

Show node lables

```console
kubectl get no -o json | jq .items[].metadata.labels
```

## Rsync

rsync exact copy

```console
sudo rsync -axHAWXS --numeric-ids --info=progress2 /mnt/sourcePart/ /mnt/destPart
```

## ISCSI

Discovering targets in iSCSI server

```console
sudo iscsiadm --mode discovery -t sendtargets --portal storage-server-lagg.lan
```

Mount disk

```console
sudo iscsiadm --mode node --targetname iqn.2005-10.org.freenas.ctl:<disk-name> --portal storage-server-lagg.lan --login
```

Unmount disk

```console
sudo iscsiadm --mode node --targetname iqn.2005-10.org.freenas.ctl:<disk-name> --portal storage-server-lagg.lan -u
```

### Repair iSCSI share

1. SSH into one of the nodes in the cluster and start discovery
   ```console
   sudo iscsiadm -m discovery -t st -p storage-server-lagg.lan
   ```
2. Login to target
   ```console
   sudo iscsiadm --mode node --targetname iqn.2005-10.org.freenas.ctl:<disk-name> --portal storage-server-lagg.lan --login
   ```
3. See the device using `lsblk`. In the following steps, assume sdd is the device name.
4. Create a local mount point & mount to replay logfile `sudo mkdir -vp /mnt/data-0 && sudo mount /dev/sdd /mnt/data-0/`
5. Unmount the device `sudo umount /mnt/data-0/`
6. Run check / ncheck `sudo xfs_repair -n /dev/sdd; sudo xfs_ncheck /dev/sdd` If filesystem corruption was corrected due to replay of the logfile, the xfs_ncheck should produce a list of nodes and pathnames, instead of the errorlog.
7. If needed run xfs repair `sudo xfs_repair /dev/sdd`
8. Logout from target
   ```console
   sudo iscsiadm --mode node --targetname iqn.2005-10.org.freenas.ctl:<disk-name> --portal storage-server-lagg.lan --logout
   ```
9. Volumes are now ready to be mounted as PVCs.

## TrueNAS

### Rename volume
```
zfs rename r01_1tb/k8s/{zvol name}
```