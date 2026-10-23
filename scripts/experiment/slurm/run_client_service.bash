#!/bin/bash
#
# DESCRIPTION: Within an existing job allocation, starts an I/O client service
# process on each node, then runs the I/O client control process on the local
# machine, waits for it to finish, then stops the service processes.
#
# USAGE: source or execute from within SLURM job script
#
# ARGS: none
#
# ENVIRONMENT:
# - USES
#     AOS_JOB_WORKDIR            - working directory for job
#     AOS_CLIENT_COMMAND         - full command to run for local client control process
#     AOS_CLIENT_SVC_COMMAND     - full command to run on each job node for client service
#     AOS_CLIENT_NODES           - number of client nodes (default: $AOS_JOB_SIZE)
#     AOS_CLIENT_PROCS_PER_NODE  - number of client processes per node (default: 1)
#     AOS_EXPERIMENT_NAME        - current experiment name
#     AOS_TEST_NAME              - current test name
#     AOS_TEST_RUN_LOG_DIR       - current test run log directory


if [ -z "$AOS_JOB_WORKDIR" ]; then
    echo "ERROR: AOS_JOB_NAME or AOS_JOB_WORKDIR not set!"
elif [ -z "$AOS_CLIENT_COMMAND" -o -z "$AOS_CLIENT_SVC_COMMAND" ]; then
    echo "ERROR: AOS_CLIENT_COMMAND or AOS_CLIENT_SVC_COMMAND not set!"
elif [ -z "$AOS_TEST_RUN_LOG_DIR" ]; then
    echo "ERROR: AOS_TEST_RUN_LOG_DIR not set!"
elif [ -z "$AOS_JOB_SIZE" ]; then
    echo "ERROR: AOS_JOB_SIZE not set!"
else
    # start services, one per node, capturing per-node stdout/err
    n_nodes=${AOS_CLIENT_NODES:-$AOS_JOB_SIZE}
    service_exe=$(echo $AOS_CLIENT_SVC_COMMAND | awk '{print $1}')
    service_name=$(basename $service_exe)

    logdir=$AOS_TEST_RUN_LOG_DIR
    [ ! -d $logdir ] && /bin/mkdir -p $logdir

    # capture full environment settings for srun
    env | sort > $logdir/env.slurm

    # note: in following, %N is substituted with short hostname
    service_output="$logdir/${AOS_EXPERIMENT_NAME}-${AOS_TEST_NAME}.${service_name}-service-%N.outerr"
    
    ppn=${AOS_CLIENT_PROCS_PER_NODE:-1}
    srun_args="--immediate -N$n_nodes --ntasks-per-node=$ppn --input=none --output=$service_output"
    if [ ${AOS_CLIENT_DEBUG:-0} -eq 1 ]; then
        srun_cmd="srun $srun_args $AOS_REPO_ROOT/scripts/experiment/gdb/gdb-wrapper.bash $AOS_CLIENT_SVC_COMMAND"
    else
        srun_cmd="srun $srun_args $AOS_CLIENT_SVC_COMMAND"
    fi

    echo >&2 "INFO: [$(date +'%T')] Launching services : $srun_cmd"
    $srun_cmd &
    srun_process=$!
    sleep 5
    
    # start client
    client_output="$logdir/${AOS_EXPERIMENT_NAME}-${AOS_TEST_NAME}.${service_name}-client.outerr"
    echo >&2 "INFO: [$(date +'%T')] Starting client: $AOS_CLIENT_COMMAND &> $client_output"
    $AOS_CLIENT_COMMAND |& tee $client_output
    client_result=$?
    echo >&2 "INFO: [$(date +'%T')] Client finished - result code is $client_result"
    AOS_TEST_CLIENT_RESULT=$client_result
    sleep 5

    # stop services
    echo >&2 "INFO: [$(date +'%T')] Stopping services"
    kill $srun_process
    sleep 5
fi
