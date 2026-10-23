#!/bin/bash
#
# DESCRIPTION: Within an existing job allocation, starts an I/O client process
# on each node and waits for it to finish.
#
# USAGE: source or execute from within SLURM job script
#
# ARGS: none
#
# ENVIRONMENT:
# - USES
#     AOS_JOB_WORKDIR            - working directory for job
#     AOS_CLIENT_COMMAND         - full command to run on each job node for client
#     AOS_CLIENT_NODES           - number of client nodes (default: $AOS_JOB_SIZE)
#     AOS_CLIENT_PROCS_PER_NODE  - number of client processes per node (default: 1)
#     AOS_EXPERIMENT_NAME        - current experiment name
#     AOS_TEST_NAME              - current test name
#     AOS_TEST_RUN_LOG_DIR       - current test run log directory

if [ -z "$AOS_JOB_WORKDIR" ]; then
    echo "ERROR: AOS_JOB_NAME or AOS_JOB_WORKDIR not set!"
elif [ -z "$AOS_CLIENT_COMMAND" ]; then
    echo "ERROR: AOS_CLIENT_COMMAND not set!"
elif [ -z "$AOS_TEST_RUN_LOG_DIR" ]; then
    echo "ERROR: AOS_TEST_RUN_LOG_DIR not set!"
elif [ -z "$AOS_JOB_SIZE" ]; then
    echo "ERROR: AOS_JOB_SIZE not set!"
else
    logdir=$AOS_TEST_RUN_LOG_DIR
    [ ! -d $logdir ] && /bin/mkdir -p $logdir

    # capture full environment settings for mpirun
    env | sort > $logdir/env.ompi

    n_nodes=${AOS_CLIENT_NODES:-$AOS_JOB_SIZE}
    n_ppn=${AOS_CLIENT_PROCS_PER_NODE:-1}
    n_procs=$(( $n_nodes * $n_ppn ))

    client_exe=$(echo $AOS_CLIENT_COMMAND | awk '{print $1}')
    client_name=$(basename $client_exe)

    # capture per-node stdout/err
    # note: in following, %N is substituted with short hostname
    client_output="$logdir/${AOS_EXPERIMENT_NAME}-${AOS_TEST_NAME}.${client_name}.outerr"

    # OpenMPI mpirun options
    sockets_per_node=${AOS_CLIENT_CPU_SOCKETS_PER_NODE:-1}
    cores_per_socket=${AOS_CLIENT_CPU_CORES_PER_SOCKET:-1}
    cores_per_node=$(( $sockets_per_node * $cores_per_socket ))
    cores_per_proc=$(( $cores_per_node / $n_ppn ))
    
    mpirun_args="--hostfile $AOS_JOB_HOST_FILE -np $n_procs --bind-to core --map-by ppr:${n_ppn}:node:pe=${cores_per_proc} --stdin none --merge-stderr-to-stdout --output-filename $client_output"
    mpirun_cmd="mpirun $mpirun_args $AOS_CLIENT_COMMAND"
    
    # start clients 
    echo >&2 "INFO: [$(date +'%T')] Launching clients : $mpirun_cmd"
    $mpirun_cmd
    client_result=$?
    echo >&2 "INFO: [$(date +'%T')] Clients finished - result code is $client_result"
    AOS_TEST_CLIENT_RESULT=$client_result
fi
