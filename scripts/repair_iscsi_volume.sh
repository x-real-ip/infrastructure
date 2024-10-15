#!/bin/bash

# Define colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Ensure the container that uses the volume has stopped.
echo -e "${YELLOW}Make sure that the container that uses the volume has stopped.${NC}"
read -p "Press Enter to proceed"

# SSH into one of the nodes in the cluster and start discovery
echo -e "${GREEN}Starting iSCSI discovery...${NC}"
sudo iscsiadm -m discovery -t st -p truenas-master.lan.stamx.nl

# Prompt for disk name and set as environment variable
echo -e "${YELLOW}Enter the disk name (for example: dsmr-reader-db) ${NC}"
read -p "disk name: " DISKNAME
export DISKNAME

# Login to target
echo -e "${GREEN}Logging in to iSCSI target...${NC}"
if sudo iscsiadm --mode node --targetname iqn.2005-10.org.freenas.ctl:${DISKNAME} --portal truenas-master.lan.stamx.nl --login; then
    echo -e "${GREEN}Logged in to ${DISKNAME} successfully.${NC}"
else
    echo -e "${RED}Failed logging in to iSCSI target '${DISKNAME}'.${NC}"
    exit 1
fi

# Wait for a few seconds to ensure the device is available
WAIT_TIME=5
echo -n -e "${YELLOW}Waiting for $WAIT_TIME seconds: ${NC}"
for ((i = WAIT_TIME; i > 0; i--)); do
    echo -n "."
    sleep 1
done
echo -e " ${GREEN}Done.${NC}"

# Display block devices and prompt for device name
lsblk
echo -e "${YELLOW}Enter the device${NC}"
read -p "Enter the device (for example: 'sda'): " DEVICENAME
export DEVICENAME

# Step 4: Create a local mount point & mount to replay logfile
echo -e "${GREEN}Creating mount point and mounting device...${NC}"
sudo mkdir -vp /mnt/data-0

# Attempt to mount the device
if sudo mount /dev/${DEVICENAME} /mnt/data-0/; then
    echo -e "${GREEN}Device mounted successfully.${NC}"
else
    echo -e "${YELLOW}Mounting failed.${NC}"
    echo -e "${YELLOW}Do you want to run 'xfs_repair -L' on ${DEVICENAME}?${NC}"

    # Ask user if they want to run xfs_repair -L
    read -p "(yes/no): " ANSWER
    if [[ "$ANSWER" == "yes" ]]; then
        echo -e "${GREEN}Running xfs_repair -L...${NC}"
        sudo xfs_repair -L /dev/${DEVICENAME}

        # Retry mounting after repair
        if sudo mount /dev/${DEVICENAME} /mnt/data-0/; then
            echo -e "${GREEN}Device mounted successfully after repair.${NC}"
        else
            echo -e "${RED}Failed to mount even after repair. Check the device and filesystem.${NC}"
            sudo iscsiadm --mode node --targetname iqn.2005-10.org.freenas.ctl:${DISKNAME} --portal truenas-master.lan.stamx.nl --logout
            exit 1
        fi
    else
        echo -e "${RED}Operation aborted. Check the device and filesystem.${NC}"
        exit 1
    fi
fi

# Wait for a few seconds to ensure the device is available
WAIT_TIME=5
for ((i = WAIT_TIME; i > 0; i--)); do
    echo -n "."
    sleep 1
done
echo -e " ${GREEN}Done.${NC}"

# Step 8: Logout from target
echo -e "${GREEN}Logging out from iSCSI target...${NC}"
sudo iscsiadm --mode node --targetname iqn.2005-10.org.freenas.ctl:${DISKNAME} --portal truenas-master.lan.stamx.nl --logout

echo -e "${GREEN}Volume '${DISKNAME} is now ready to be mounted as PVC.${NC}"
