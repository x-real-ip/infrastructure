# Cheatsheet

## Convert to BASE64
```batch
echo -n '<value>' | base64
```

## Restart Pod
```batch
kubectl rollout restart deployment <deployment name> -n <namespace>
```

## Reuse PV in PVC
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
