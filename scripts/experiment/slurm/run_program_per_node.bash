# DESCRIPTION: Within an existing job allocation, launches the program
# given as command-line args on each node. Defines 'srun_process' to the
# pid of the srun process, which can be used to wait on or terminate the
# program.
#
# USAGE: source this from inside SLURM job script.
#
# ARGS: program ($1) and any arguments
#
# ENVIRONMENT:
# - USES
#     AOS_JOB_WORKDIR      - working directory for job
#     SLURM_JOB_NUM_NODES

datestamp=$(date +'%Y%m%d_%H%M%S')

program_name=$(basename $1)

n_nodes=${AOS_CLIENT_NODES:-$AOS_JOB_SIZE}

# capture per-node stdout/err
# %N - short hostname
# %j - jobid
program_output="$AOS_JOB_WORKDIR/${program_name}-%N.%j.outerr.${datestamp}"
srun_args="--immediate -N$n_nodes --ntasks-per-node=1 --input=none --output=$program_output"
srun_cmd="srun $srun_args $@"
echo >&2 "INFO: [$(date +'%T')] Launching program on all job nodes : $srun_cmd"
$srun_cmd &
srun_process=$!
