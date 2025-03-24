- [Installer](#installer)
- [Disks and partitioning](#disks-and-partitioning)
- [Network](#network)
- [Import ZFS pool](#import-zfs-pool)
- [Post install scripts](#post-install-scripts)
- [High Availability](#high-availability)


# Installer
1. Install Proxmox with default Partitioning.
2. Hostname pve-b or pve-a
3. Domain lan.stamx.nl

# Disks and partitioning
1. Remove lve-local via the proxmox UI.
2. Remove the data partition.
   ```
   lvremove pve/data
   ```
3. Extend the root logical volume and resize.
   ```
   lvextend -l +100%FREE /dev/pve/root
   ```
   ```
   resize2fs /dev/pve/root
   ```
4. Update the system.
   ```
   update-initramfs -u
   ```

# Network
1. Backup default network interfaces file
   ```
   cp /etc/network/interfaces /etc/network/interfaces.bak
   ```
2. Change network settings
   ```
   nano /etc/network/interfaces
   ```
3. Paste the following content for pve-a
   ```
    auto lo
    iface lo inet loopback

    iface enp0s31f6 inet manual
    #Onboard

    iface enp4s0f0 inet manual
    #PCI

    iface enp4s0f1 inet manual
    #PCI

    auto vmbr0
    iface vmbr0 inet static
            address 10.0.99.2/24
            gateway 10.0.99.1
            bridge-ports enp0s31f6
            bridge-stp off
            bridge-fd 0
    #mgmt

    auto vmbr1
    iface vmbr1 inet manual
            bridge-ports enp4s0f0
            bridge-stp off
            bridge-fd 0
            bridge-vlan-aware yes
            bridge-vids 2-4094
    #wan

    auto vmbr2
    iface vmbr2 inet manual
            bridge-ports enp4s0f1
            bridge-stp off
            bridge-fd 0
            bridge-vlan-aware yes
            bridge-vids 2-4094
    #lan
    
    source /etc/network/interfaces.d/*
 
   ```

   Paste the following content for pve-b
   ```
    auto lo
    iface lo inet loopback

    iface eno1 inet manual
    #Onboard

    iface enp3s0f0 inet manual
    #PCI

    iface enp3s0f1 inet manual
    #PCI

    auto vmbr0
    iface vmbr0 inet static
    address 10.0.99.3/24
    gateway 10.0.99.1
    bridge-ports eno1
    bridge-stp off
    bridge-fd 0
    #mgmt

    auto vmbr1
    iface vmbr1 inet manual
    bridge-ports enp3s0f0
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes
    bridge-vids 2-4094
    #wan

    auto vmbr2
    iface vmbr2 inet manual
    bridge-ports enp3s0f1
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes
    bridge-vids 2-4094
    #lan

    source /etc/network/interfaces.d/*
    
   ```

5. Reboot
   ```
   reboot now
   ```

# Import ZFS pool
1. List zfs pools and check if vm-storage pool exist.
   ```
   zpool import
   ```
2. Import zfs pool
   ```
   zpool import -f vm-storage
   ```
3. Reboot
   ```
   reboot now
   ```
4. Add pool to the UI
   1. Go to `Datacenter` -> `Storage` -> `Add` -> `ZFS` -> Select `vm-storage` and enter id `vm-storage`

# Post install scripts
   The scripts can be found at https://community-scripts.github.io/ProxmoxVE/

1. Run the 'Proxmox VE CPU Scaling Governor' script and set it to `powersaving` https://community-scripts.github.io/ProxmoxVE/scripts?id=scaling-governor
2. Run the 'Proxmox VE Post Install' script https://community-scripts.github.io/ProxmoxVE/scripts?id=post-pve-install
3. Run the 'Proxmox VE Kernel Clean' script to clean up old kernels https://community-scripts.github.io/ProxmoxVE/scripts?id=kernel-clean

# High Availability

1. 