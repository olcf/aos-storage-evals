#!/bin/bash

if [ $# -ne 4 ]; then
    echo "USAGE ERROR: $0 <pool-name> <container-name> <local-mount-point> <log-directory>"
    exit 1
fi

pool=$1
cont=$2
mntdir=$3
logdir=$4

if [ ! -d $mntdir ]; then
    mkdir -p $mntdir
    chmod 775 $mntdir # needs group write
fi

# capture dfuse log
myhost=`hostname`
export D_LOG_FILE=$logdir/dfuse.log.$myhost

# do the mount
dfuse $mntdir $pool $cont
