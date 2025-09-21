- [Installer](#installer)
- [Disks and partitioning](#disks-and-partitioning)
- [Network](#network)
- [Import ZFS pool](#import-zfs-pool)
- [Post install scripts](#post-install-scripts)
- [High Availability](#high-availability)
  - [Add QDevice](#add-qdevice)
    - [On the Qdevice](#on-the-qdevice)
    - [On the Proxmox node(s)](#on-the-proxmox-nodes)
    - [On any of Proxmox node(s)](#on-any-of-proxmox-nodes)
  - [Make a VM HA](#make-a-vm-ha)

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
       pre-up ethtool -G $IFACE rx 4096 tx 4096
       pre-up ethtool -C $IFACE rx-usecs 0
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
       pre-up ethtool -G $IFACE rx 4096 tx 4096
       pre-up ethtool -C $IFACE rx-usecs 0
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

4. Reboot
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

## Add QDevice

### On the Qdevice

1. This command sets the root password, enables root login in the SSH configuration, and restarts the SSH service.

   ```bash
   sudo passwd root && sudo sed -i 's/#PermitRootLogin/PermitRootLogin yes/' /etc/ssh/sshd_config && sudo systemctl restart sshd
   ```

2. Install corosync packages
   ```bash
   sudo apt install corosync-qnetd corosync-qdevice
   ```

### On the Proxmox node(s)

3. Install corosync-qdevice packages. Repeat for each node in your cluster.
   ```bash
   apt update && apt install corosync-qdevice -y
   ```

### On any of Proxmox node(s)

4. Check current status

   ```bash
   pvecm status
   ```

   the output should look like this

   ```txt
   Cluster information
   -------------------
   Name:             pve-cluster
   Config Version:   2
   Transport:        knet
   Secure auth:      on

   Quorum information
   ------------------
   Date:             Wed Mar 26 13:41:51 2025
   Quorum provider:  corosync_votequorum
   Nodes:            2
   Node ID:          0x00000002
   Ring ID:          1.16
   Quorate:          Yes

   Votequorum information
   ----------------------
   Expected votes:   2
   Highest expected: 2
   Total votes:      2
   Quorum:           2
   Flags:            Quorate

   Membership information
   ----------------------
      Nodeid      Votes Name
   0x00000001          1 10.0.99.2
   0x00000002          1 10.0.99.3 (local)
   ```

5. Add the QDevice to the cluster. Run this on one of the Proxmox nodes. Change the IP address to the IP of the Qdevice

   ```bash
   pvecm qdevice setup 10.0.99.102 -f
   ```

6. Once this is completed check if the Qdevice has been added to the cluster.

   ```
   pvecm status
   ```

   The output should now look similar like this:

   ```txt
      Cluster information
   -------------------
   Name:             pve-cluster
   Config Version:   3
   Transport:        knet
   Secure auth:      on

   Quorum information
   ------------------
   Date:             Wed Mar 26 13:51:33 2025
   Quorum provider:  corosync_votequorum
   Nodes:            2
   Node ID:          0x00000002
   Ring ID:          1.16
   Quorate:          Yes

   Votequorum information
   ----------------------
   Expected votes:   3
   Highest expected: 3
   Total votes:      3
   Quorum:           2
   Flags:            Quorate Qdevice

   Membership information
   ----------------------
      Nodeid      Votes    Qdevice Name
   0x00000001          1    A,V,NMW 10.0.99.2
   0x00000002          1    A,V,NMW 10.0.99.3 (local)
   0x00000000          1            Qdevice
   ```

## Make a VM HA

1. Turn on Replication for the VM that you want to make High Available.
2. Go to `Datacenter` -> `HA` and add a Resource.
