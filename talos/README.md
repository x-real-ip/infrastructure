Generate config
```bash
talosctl gen config "k8s-cluster-01" "https://192.168.1.x:6443"
```
change controleplane.yaml
```bash
talosctl apply-config --insecure \
--nodes 192.168.1.144 \
--file k8s-master-02.yaml
```

Set controlplane endpoints in config
```bash
talosctl --talosconfig=./talosconfig \
config endpoint 192.168.1.11
```

Set a default node in de config
```bash
talosctl --talosconfig=./talosconfig \
config node 192.168.1.11
```

Bootstrap Etcd
```bash
talosctl --talosconfig ./talosconfig config endpoint 192.168.1.11
talosctl --talosconfig ./talosconfig config node 192.168.1.11
```

```bash
talosctl --talosconfig ./talosconfig bootstrap --nodes 192.168.1.11 --endpoints 192.168.1.11
```

Edit machine config
```talosctl -n 192.168.1.12 edit machineconfig```
