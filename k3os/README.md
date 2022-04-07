See https://github.com/rancher/k3os/blob/master/README.md#configuration
and https://github.com/rancher/k3os/blob/master/README.md#remastering-iso

1. Download ISO file from https://github.com/rancher/k3os/releases
2. Create ISO with custom config.yaml and upload ISO to Proxmox

```
apt install grub-efi grub-pc-bin mtools xorriso

mount -o loop k3os.iso /mnt
mkdir -p iso/boot/grub
cp -rf /mnt/k3os iso/
cp /mnt/boot/grub/grub.cfg iso/boot/grub/
```

Create custom config.yaml in ../k3os/iso/k3os/

```yaml
# This file is a placeholder for custom configuration when building a custom ISO image.
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCdD/NgT7GF9tQPnw9M7qPIEOFzm9CGcYZS4DiZcVPjRGrtwTRV7jzsWjvJKVVxGxNmvyz+vP2zfEgHlluWT2XRpKha3u8SX8iv3gHATME93j2Vk2jPDkKvDHXIoArFj5wjvHbwSSNOPjmUAgJvqDT4zK/owARGSrNpgfD3hjYm+3Hf/gGhbfgaVyuSJT3iDeG7hCeoCqZ8bBBkOSJddlFEksgNZpK83vVlxVsvEpqBXU5ZDH7f/6i+qoxz9M7oBmHcNkl60KVbUnhcE9BmYVx9B578zQ6bp0PS4OcVp5l+RAIalVc5YTZ685HQ0zkJmabLjyz/hFbHMBfblq6XGz36UtU/ug7twejVLT1soy0ljAQ2FuEOeqvpi1uIm5gpVqxh0yHd65aFFvXoCf64QJJXYnF0Ljpbohhu9Mqzs7jeA1Ar2W3DwLgsRtoTBlvspUNf3F0PQv0do9UBgrxy9ZIbtA4wxVuTHXrGzkygY9WCsUH5gHksMcU5tZX/e7nTcN2Oj+fo7MiiNpz66oXaJo7ByGzjF7iVUB4fwnf67wq0sdftMF+A28X06VRxhvJS6ocee7pg9zShkOezofUg02LuWKr//QeKbRUGFspOEojazQFt2IwmL0gbHjdz7JkgMVPWbJxDa4LUJEpESb18ONDAtnBEKotK0aTaahBbnBMNBQ== coen@laptop-3
```

Write create new ISO

```bash
grub-mkrescue -o k3os-new.iso iso/ -- -volid K3OS
```

3. Create VM with custom K3os .ISO

4. After installation create config.yaml

Insert for server: https://github.com/theautomation/kubernetes-k3s/blob/main/k3os/worker/config.yaml
Insert fro worker: https://github.com/theautomation/kubernetes-k3s/blob/main/k3os/server/config.yaml

```bash
sudo vi /var/lib/rancher/k3os/config.yaml
```

5. Apply config

```bash
sudo k3os cfg --boot
```

6. Reboot

```bash
sudo reboot
```
