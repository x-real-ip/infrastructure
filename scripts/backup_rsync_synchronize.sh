#!/bin/bash
#
# This script will backup files and folders from local machine to a remote machine over ssh.
# Writtin by Coen Stam.
# github@theautomation.nl
#

set -e

# -----------------------------------------------------------------------------------
# Select if ssh configuation from /.ssh/config must be used or not.
# See also https://github.com/x-real-ip/hosts-config/tree/main/backup-host#setup-ssh
# 1 = use the user, host and port from a ssh config file stored in /.ssh/config.
# 0 = use ssh variables user, host and port from the variables below.
ssh_config="0"

# If ssh_config => 1
# Remote hostname from .ssh/config.
remote_host_from_config="backup-host"

# If ssh_config => 0
# User of the remote host.
remote_user="coen"
# Ip address of the remote host.
remote_host="192.168.1.234"
# Remote ssh port.
remote_port=2244

# Rsync options in command (optional).
# More options can be found at https://linux.die.net/man/1/rsync
rsync_options=(
    "--archive"
    "--partial"
    "--stats"
    "--progress"
    "--verbose"
    "--delete"
)

# Absolute path of the exclude list location for rsync as external file.
rsync_excludelist="/home/coen/hosts-config/proxmox-ve/docker-host/backup_exclude"

# Rsync source path being copied
rsync_sourcepaths=(
    "/mnt/R10_S8TB_C120GB/coen"
    "/mnt/R10_S8TB_C120GB/anne"
    # "/mnt/R10_S8TB_C120GB/temp"
)

# Destination path for rsync
rsync_destinationpath="/media/external2"
# -----------------------------------------------------------------------------------

echo "Starting backup of ${rsync_sourcepaths[@]}..."

if [ "${ssh_config}" = "1" ]; then
    if [ ! -f "${HOME}"/.ssh/config ]; then
        echo "Script stopped, ssh_config is set to 1 but there is no .ssh config file found in ${HOME}/.ssh/, create ssh config file or set ssh_config => 0 to use <user>, <host>, <port> from the variables in this script."
        exit 2
    elif [ -z "${remote_host_from_config}" ]; then
        echo "Script stopped, ssh_config is set to 1 but backup_host variable is empty."
        exit 3
    else
        echo "Starting rsync using ssh config file..."
        for sourcepath in ${rsync_sourcepaths[@]}; do
            rsync ${rsync_options[@]} --exclude-from="${rsync_excludelist}" "${sourcepath}" ${remote_host_from_config}:${rsync_destinationpath}
        done
    fi
    echo "Start rsync with <user>, <host>, <port> from .ssh/config..."
elif [ "${ssh_config}" = "0" ]; then
    if [ -z "${remote_user}" ] || [ -z "${remote_host}" ] || [ -z "${remote_port}" ]; then
        echo "script stopped, ssh_config is set to 0 but one or more variables for are undefined, check remote user, host and port variable(s)"
        exit 4
    else
        echo "Start rsync with ${remote_user}, ${remote_host}, ${remote_port} from script variable..."
        for sourcepath in ${rsync_sourcepaths[@]}; do
            rsync ${rsync_options[@]} --exclude-from="${rsync_excludelist}" --delete-excluded -e "ssh -p ${remote_port}" "${sourcepath}" ${remote_user}@${remote_host}:${rsync_destinationpath}
        done
    fi
fi

echo "All done..."
exit 0
