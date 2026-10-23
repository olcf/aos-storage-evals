#!/bin/bash

if [ $# -ne 3 ]; then
    echo "USAGE ERROR: $0 <pool-name> <container-name> <local-mount-point>"
    exit 1
fi

pool=$1
cont=$2
mntdir=$3

# issue the container creation command
group_name=${AOS_PROJECT_GROUP:-"stf008"}
daos container create -t POSIX --properties rd_fac:2 -g $group_name $pool $cont
create_rc=$?
if [ $create_rc -eq 0 ]; then
    # print the container details
    echo "Successfully created container $cont in pool $pool."
    echo "- Printing summary:"
    daos container query $pool $cont
    echo "- Printing ACL:"
    daos container get-acl $pool $cont

    # do the mount
    if [ ! -d $mntdir ]; then
        mkdir -p $mntdir
    fi
    echo "- Testing local mount:"
    dfuse $mntdir $pool $cont
    mnt_rc=$?
    if [ $mnt_rc -eq 0 ]; then
        # Just in case other group members will need to use it, update access from within
        # container root. Note that world rwx permissions are necessary for any programs
        # using libdfs directly, since it does no owner/group verfication.
        cd $mntdir && chgrp $group_name . && chmod 777 . && ls -ld . && cd -
        fusermount3 -u $mntdir
    else
        echo "ERROR: dfuse mount failed for new POSIX container"
        exit $mnt_rc
    fi
else
    echo "ERROR: daos container creation failed for new POSIX container"
    exit $create_rc
fi
