#!/bin/bash
#
# this script will tarball and backup files and folders from local machine to a remote machine over ssh.
# script writtin by Coen Stam.
# c.github@stamx.nl
#

set -ex

# ----------------------------------------------------------------------------------- 
# select if ssh configuation from /.ssh/config must be used or not.
# 1 = use the user, host and port from a ssh config file stored in /.ssh/config.
# 0 = use ssh variables user, host and port from the variables below in this script.
ssh_config="1"

# if ssh_config => 1 
# remote hostname from .ssh/config.
remote_host_from_config="backup-host"

# if ssh_config => 0
# user of the remote host.
remote_user="coen"
# ip address of the remote host.
remote_host="192.168.1.234"
# remote ssh port.
remote_port=2244

# rsync options in command (optional).
# more options can be found at https://linux.die.net/man/1/rsync
rsync_options="--archive --partial --stats --remove-sent-files"

# absolute path of the exclude list location for rsync as external file.
rsync_excludelist="/home/coen/hosts-config/proxmox-ve/docker-host/backup_exclude"

# absolute path to source location for tarball with tar.
tar_sourcepath="/home/coen/docker-home-services"

# absolute destination path for saving tar file.
tar_destinationpath="/backup-pool/coen/purge/"

# tar options in command (optional)
# more options can be found at https://linux.die.net/man/1/tar
tar_options="--create --gzip"

# filename of the tar file.
tar_name="$(date '+%y-%m-%d').tar.gz"

# temporary directory for tar file
# the tar file will be deleted when the rsync command has run successfull in this script.
tar_tempdir="/mnt/slow-storage/temp"

# number of days to keep tar files on backup.
# e.g. "+31" will delete tar file(s) older than 31 days, "-1" delete tar file(s) less than 1 day.
tar_days="+31"
# -----------------------------------------------------------------------------------
tarball_function () {
if [ ! -d ${tartempdir} ]
then
  mkdir ${tartempdir}
  echo "created temporary directory for tar file in ${tar_tempdir}."
fi

if [ ! -f ${rsync_excludelist} ]
then
  echo "script stopped, there is no exclude list in $PWD/"
  exit 1
fi

echo "starting tar..."
tar ${tar_options} --file ${tar_tempdir}/${tar_name} ${tar_sourcepath}
}

echo "Starting backup of ${tar_sourcepath}."

if [ "${ssh_config}" = "1" ]
then
  if [ ! -f ${HOME}/.ssh/config ]
  then
    echo "script stopped, ssh_config is set to 1 but there is no .ssh config file found in ${HOME}/.ssh/, create ssh config file or set ssh_config => 0 to use <user>, <host>, <port> from the variables in this script."
    exit 2
  elif [ -z "${remote_host_from_config}" ]
  then
    echo "script stopped, ssh_config is set to 1 but backup_host variable is empty."
    exit 3
  else
  tarball_function
  echo "starting rsync using ssh config file"
  rsync ${rsync_options} --exclude-from="${rsync_excludelist}" ${tar_tempdir}/*.tar* ${remote_host_from_config}:${tar_destinationpath}
  echo "deleting tar files on remote machine older than ${tar_days} days..."
  ssh ${remote_host_from_config} "find ${tar_destinationpath} -type f -mtime ${tar_days} -name *.tar* -ls -delete"
  fi
    echo "start rsync with <user>, <host>, <port> from .ssh/config..."
elif [ "${ssh_config}" = "0" ]
then
  if [ -z "${remote_user}" ] || [ -z "${remote_host}" ] || [ -z "${remote_port}" ]
  then
  echo "script stopped, ssh_config is set to 0 but one or more variables for are undefined, check remote user, host and port variable(s)"
  exit 4
  else
  tarball_function
  echo "start rsync with ${remote_user}, ${remote_host}, ${remote_port} from script variable..."
  rsync ${rsync_options} --exclude-from="${rsync_excludelist}" -e "ssh -p ${remote_port}" ${tar_tempdir}/*.tar* ${remote_user}@${remote_host}:${tar_destinationpath}
  echo "deleting tar files on remote machine older than ${tar_days} days..."
  ssh -p ${remote_port} ${remote_user}@${remote_host} "find ${tar_destinationpath} -type f -mtime ${tar_days} -name *.tar* -ls -delete"
  fi
fi

echo "all done..."
exit 0
