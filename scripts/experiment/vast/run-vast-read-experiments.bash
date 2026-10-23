#!/bin/bash

# NOTE: this is for the large-file, small-files-xxx experiments only

export AOS_PLATFORM_SERVER=vast

# USAGE: pass experiment names as script args
experiments="$*"
for exp in $experiments; do 
   echo; echo "Running experiment: $exp"; 
   $AOS_REPO_ROOT/experiments/$exp/scripts/run/run-copy-read-remove.bash daos://datasets /proj/$USER/scratch/$AOS_PLATFORM_CLIENT/data/job.$SLURM_JOBID ; 
   echo ; echo "Completed experiment: $exp"; 
done
