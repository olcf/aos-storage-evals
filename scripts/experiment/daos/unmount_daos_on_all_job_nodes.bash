#!/bin/bash

if [[ -z $AOS_REPO_ROOT ]]; then
    echo "ERROR: AOS_REPO_ROOT is not set!"
    exit 1;
fi

if [[ -z $AOS_JOB_HOST_FILE ]]; then
    echo "ERROR: AOS_JOB_HOST_FILE is not set!"
    exit 1;
fi

if [[ -z $AOS_DAOS_LOCAL_MOUNT_DIR ]]; then
    echo "ERROR: AOS_DAOS_LOCAL_MOUNT_DIR is not set!"
    exit 1;
fi
localdir=$AOS_DAOS_LOCAL_MOUNT_DIR

# doing this via ssh for-loop since the mount doesn't work properly when run using srun
for host in `cat $AOS_JOB_HOST_FILE`; do
    # the dfuse_mount.bash script creates the local directory for us if necessary
    ssh $host $AOS_REPO_ROOT/scripts/experiment/daos/dfuse_unmount.bash $localdir
done