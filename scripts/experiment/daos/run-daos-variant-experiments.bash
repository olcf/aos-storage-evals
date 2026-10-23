#!/bin/bash

# NOTE: This is for run scripts that take a single target argument (like dlio and fst)

# USAGE: pass experiment and run script name as script args
experiment="$1"
runscript_name="$2"

if [ -z "$experiment" ]; then
    echo "USAGE: $0 <experiment> <run-script-name>"
    exit 1
fi

if [ -z "$runscript_name" ]; then
    echo "USAGE: $0 <experiment> <run-script-name>"
    exit 1
fi

runscript="$AOS_REPO_ROOT/experiments/$experiment/scripts/run/$runscript_name"
if [ ! -x $runscript ]; then
    echo "Run script not found: $runscript"
    exit 1
fi

$AOS_REPO_ROOT/scripts/experiment/daos/create_posix_container.bash aos job-$SLURM_JOBID /tmp/$USER/daos-mount/job-$SLURM_JOBID
if [ $? -eq 0 ]; then
    for platform in fuse ioil dfs; do
	export AOS_PLATFORM_SERVER=daos-$platform
        echo; echo "Running experiment $experiment on $AOS_PLATFORM_SERVER"; 
        $runscript daos://aos/job-$SLURM_JOBID ; 
        echo ; echo "Completed experiment: $experiment"; 
    done
fi
