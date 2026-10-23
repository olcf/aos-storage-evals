#!/bin/bash

# NOTE: this is for the large-file, small-files-xxx experiments only

# USAGE: pass experiment names as script args
experiments="$*"

$AOS_REPO_ROOT/scripts/experiment/daos/create_posix_container.bash aos job-$SLURM_JOBID /tmp/$USER/daos-mount/job-$SLURM_JOBID
if [ $? -eq 0 ]; then
    for exp in $experiments; do 
        echo; echo "Running experiment: $exp"; 
        $AOS_REPO_ROOT/experiments/$exp/scripts/run/run-copy-read-remove.bash $AOS_PROJECT_DIR/datasets daos://aos/job-$SLURM_JOBID ; 
        echo ; echo "Completed experiment: $exp"; 
    done
fi
