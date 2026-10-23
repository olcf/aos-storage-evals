# DESCRIPTION: Uses the SLURM scontrol command to get the list of hosts assigned
# to this job, and stores the host names in a file (AOS_JOB_HOST_FILE) and as a
# comma-separated list (AOS_JOB_HOST_LIST).
#
# USAGE: source this from within job script
#
# ARGS: none
#
# ENVIRONMENT:
# - USES
#     AOS_JOB_WORKDIR    - working directory for job
#     SLURM_JOBID
# - DEFINES
#     AOS_JOB_HOST_FILE  - File containing job hosts (one per line)
#     AOS_JOB_HOST_LIST  - String with comma-separated job hosts
#     AOS_JOB_SIZE       - Number of allocated hosts

if [ -z "$SLURM_JOBID" ]; then
    echo "ERROR: SLURM_JOBID is not set!"
elif [ -z "$AOS_JOB_SIZE" ]; then
    export AOS_JOB_SIZE=$SLURM_JOB_NUM_NODES
    export AOS_JOB_HOST_FILE=$AOS_JOB_WORKDIR/job.hosts.${SLURM_JOBID}
    if [ ! -f $AOS_JOB_HOST_FILE ]; then
        scontrol show hostnames > $AOS_JOB_HOST_FILE
        export AOS_JOB_HOST_LIST=$(cat $AOS_JOB_HOST_FILE | tr "\n" "," | sed -e 's/,$//')
        [[ -n "$AOS_SCRIPT_DEBUG" && $AOS_SCRIPT_DEBUG -eq 1 ]] && echo >&2 "DEBUG: Job Hosts : $AOS_JOB_HOST_LIST"
    fi
fi
