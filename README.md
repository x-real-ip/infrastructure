# infrastructure

- [infrastructure](#infrastructure)
  - [Kubernetes](#kubernetes)
    - [Prerequisites](#prerequisites)
    - [Add SSH keys on local device](#add-ssh-keys-on-local-device)
    - [Setting up VM hosts on Proxmox](#setting-up-vm-hosts-on-proxmox)
    - [Install k3s](#install-k3s)
      - [Usage](#usage)
    - [Local initialization and setup](#local-initialization-and-setup)
      - [Kubectl](#kubectl)
      - [Bitnami Kubeseal](#bitnami-kubeseal)
    - [Kubernetes Cheatsheet](#kubernetes-cheatsheet)
    - [Bitnami Sealed Secret](#bitnami-sealed-secret)
    - [Node Feature Discovery](#node-feature-discovery)
  - [Rsync](#rsync)
  - [ISCSI](#iscsi)
    - [Repair iSCSI share](#repair-iscsi-share)
  - [TrueNAS](#truenas)
    - [Rename volume](#rename-volume)
  - [Resize VM disk](#resize-vm-disk)
  - [Odroid](#odroid)

## Kubernetes

### Prerequisites

- Ansible installed on your local machine.
- SSH access to the target machines where you want to install k3s.

### Add SSH keys on local device

1. Copy private and public key

```bash
cp /path/to/my/key/ansible ~/.ssh/ansible
cp /path/to/my/key/ansible.pub ~/.ssh/ansible.pub
```

2. Change permissions on the files

```bash
sudo chmod 600 ~/.ssh/ansible
sudo chmod 600 ~/.ssh/ansible.pub
```

3. Make ssh agent to actually use copied key

```bash
ssh-add ~/.ssh/ansible
```

### Setting up VM hosts on Proxmox

1. Create a VM with the following partitions
   - / (10 GB) xfs
   - /var (50GB) xfs
   - /boot (1GB)
  
    No swap partition is needed for kubernetes

2. Login to the VM and set hostname.
   ```console
   hostnamectl set-hostname <hostname>
   ```
3. Reboot.
4. Set static ip for the VM in the DHCP server.

5. Reboot.
6. Set this hostname in the ansible inventory hosts.ini file.

### Install k3s

#### Usage

1. Clone this repository to your local machine:

```
git clone https://github.com/x-real-ip/infrastructure.git
```

2. Modify the inventory file inventory.ini to specify the target machines where you want to install k3s. Ensure you have appropriate SSH access and privileges.
3. Run one of the following Ansible playbooks to initialize the k3s master and optional worker nodes:
   1. Bare Installation:
      Execute the k3s_install_cluster_bare.yaml playbook to install a clean cluster without additional deployments:
      ```
      sudo ansible-playbook --ask-vault-pass -kK k3s_install_cluster_bare.yaml
      ```
   2. Minimal Installation with Additional Deployments:
      Execute the k3s_install_cluster_minimal.yaml playbook to install the bare minimum plus additional deployments:
      ```
      sudo ansible-playbook --ask-vault-pass -kK k3s_install_cluster_minimal.yaml
      ```

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

Raw mode

```
echo -n foo | kubeseal --cert "./sealed-secret-tls-2.crt" --raw --scope cluster-wide
```

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
sudo iscsiadm --mode discovery -t sendtargets --portal storage-server-lagg.lan.stamx.nl
```

Mount disk

```console
sudo iscsiadm --mode node --targetname iqn.2005-10.org.freenas.ctl:<disk-name> --portal storage-server-lagg.lan.stamx.nl --login
```

Unmount disk

```console
sudo iscsiadm --mode node --targetname iqn.2005-10.org.freenas.ctl:<disk-name> --portal storage-server-lagg.lan.stamx.nl -u
```

### Repair iSCSI share

1. Make sure that the container that uses the volume has stopped.
2. SSH into one of the nodes in the cluster and start discovery

```bash
sudo iscsiadm -m discovery -t st -p truenas-master.lan.stamx.nl && \
read -p "Enter the disk name: " DISKNAME && \
export DISKNAME
```

3. Login to target

```bash
sudo iscsiadm --mode node --targetname iqn.2005-10.org.freenas.ctl:${DISKNAME} --portal truenas-master.lan.stamx.nl --login && \
sleep 5 && \
lsblk && \
read -p "Enter the device ('sda' for example): " DEVICENAME && \
export DEVICENAME
```

4. Create a local mount point & mount to replay logfile

```bash
sudo mkdir -vp /mnt/data-0 && sudo mount /dev/${DEVICENAME} /mnt/data-0/
```

5. Unmount the device

```bash
sudo umount /mnt/data-0/
```

6. Run check / ncheck

```bash
sudo xfs_repair -n /dev/${DEVICENAME}; sudo xfs_ncheck /dev/${DEVICENAME}
echo "If filesystem corruption was corrected due to replay of the logfile, the xfs_ncheck should produce a list of nodes and pathnames, instead of the errorlog."
```

8. If needed run xfs repair

```bash
sudo xfs_repair /dev/${DEVICENAME}
```

9.  Logout from target

```bash
sudo iscsiadm --mode node --targetname iqn.2005-10.org.freenas.ctl:${DISKNAME} --portal storage-server-lagg.lan.stamx.nl --logout
echo "Volumes are now ready to be mounted as PVCs."
```

## TrueNAS

### Rename volume

```
zfs rename r01_1tb/k8s/{current zvol name} r01_1tb/k8s/{new zvol name}
```

## Resize VM disk

```
sudo dnf install cloud-utils-growpart

sudo growpart /dev/sda 2

sudo pvresize /dev/sda2

sudo lvextend -l +100%FREE /dev/mapper/rl-root

sudo xfs_growfs /

```

## Odroid

1. Download the minimal .xz-compressed image file from https://fi.mirror.armbian.de/archive/odroidc4/archive/
2. Write the .xz compressed image with a tool USBImager or balenaEtcher
3. Insert the SD/MMC and boot
4. Login via SSH user `root` default password `1234`
5. Run Ansible playbook for Odroid
