
# Setup

1. Proxmox server installed for VM k8s master and worker nodes
2. Terraform local installation
3. kubeseal binary to use Bitnami sealed serets in k8s

After terraform apply

# Connect remotely to the cluster

1. Install kubectl on your local machine.
   Read the [following page](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) to know how to install kubectl on Linux.

2. Copy the k3s config file from the master node to your local machine

```bash
mkdir ~/.kube/
scp coen@k3s-master-01.lan:/etc/rancher/k3s/k3s.yaml ~/.kube/config
export KUBECONFIG=~/.kube/config
```

3. Set right ipaddress to Master node in the config file

Test

```
kubectl get nodes
```

# Kubernetes 

## Cheatsheet

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