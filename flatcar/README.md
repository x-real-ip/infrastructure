curl -o ignition.json https://raw.githubusercontent.com/theautomation/kubernetes-k3s/main/flatcar/ignition.json

flatcar-install -d /dev/sda -C stable -i ignition.json

# After installation

1. shutdown VM `sudo shutdown'
2. Remove ISO from VM
3. Start VM

# Post installation steps

1. Set hostname

```bash
hostnamectl set-hostname k3s-master-**
```
