Generate config
```bash
talosctl gen config "k8s-cluster-01" "https://192.168.130:6443"
```
change controleplane.yaml
```bash
talosctl apply-config --insecure \
--nodes 192.168.1.150 \
--file k8s-worker-01.yaml
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

```bash
talosctl --talosconfig=./talosconfig \
bootstrap --nodes 192.168.1.11 --endpoints 192.168.1.11
```

Get kubeconfig
```bash
talosctl --talosconfig=./talosconfig \
kubeconfig
```
