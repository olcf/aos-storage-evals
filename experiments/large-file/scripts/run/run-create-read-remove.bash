#!/bin/bash

if [ $# -ne 1 ]; then
    echo "ERROR: target data directory not provided!"
    echo "USAGE: $0 <target-dir>"
    exit 1
fi

target_dir=$1

if [ -z "$AOS_REPO_ROOT" -o -z "$AOS_PLATFORM_SERVER" -o -z "$AOS_PLATFORM_CLIENT" ]; then
    echo "USAGE ERROR: Please set AOS_REPO_ROOT, AOS_PLATFORM_SERVER, and AOS_PLATFORM_CLIENT"
    exit 1
fi

export AOS_JOB_WORKDIR=$PWD

# get AOS_JOB_SIZE, AOS_JOB_HOST_LIST, and AOS_JOB_HOST_FILE
source $AOS_REPO_ROOT/scripts/experiment/slurm/get_slurm_job_hosts.bash

experiment="large-file"
export AOS_EXPERIMENT_NAME=$experiment

# run these tests in this order
tests="create read remove"
testset=$(echo $tests | sed -e 's/ /-/g')

node_counts="2 4 8 12 16"
procs_per_node="24 48"

KIB=1024
MIB=1048576
GIB=$(( $KIB * $MIB ))

file_sizes_gib="384 768 1536 3072 6144"
io_sizes="$((64 * $MIB)) $((512 * $MIB))"

# iterate over number of client nodes
for n_nodes in $node_counts; do

    # skip node counts that do not fit within current job
    [ $n_nodes -gt $AOS_JOB_SIZE ] && continue

    export AOS_CLIENT_NODES=$n_nodes

    # iterate over number of processes per client node
    for ppn in $procs_per_node; do
        export AOS_CLIENT_PROCS_PER_NODE=$ppn

        # iterate over target file sizes
        for file_sz_gib in $file_sizes_gib; do
            file_sz=$(( $file_sz_gib * $GIB ))
            export AOS_IO_FILE_SIZE=$file_sz

            # iterate over I/O request sizes
            for io_req_sz in $io_sizes; do
                io_req_sz_mib=$(( $io_req_sz / $MIB ))
                export AOS_IO_REQUEST_SIZE=$io_req_sz

                # using this config, run the sequenced test set within a single experiment
                testset_cfg="NODES_${n_nodes}.PPN_${ppn}.FSZ_${file_sz_gib}GiB.IOSZ_${io_req_sz_mib}MiB"
                runstamp=$(date +'exp.%Y%m%d_%H%M%S')
                export AOS_EXPERIMENT_RUN_STAMP=$runstamp
                
                # set target name using size and runstamp
                export AOS_TARGET=$target_dir/ds.$experiment.${file_sz_gib}GiB.$runstamp
                
                exp_rundir=$AOS_JOB_WORKDIR/$experiment/$testset/$testset_cfg/$AOS_PLATFORM_SERVER/$runstamp
                mkdir -p $exp_rundir && cd $exp_rundir
                export AOS_EXPERIMENT_RUN_DIR=$PWD # this works even if prior directory creation fails
                for test in $tests; do
                    export AOS_TEST_NAME=$test
                    testlog=${experiment}-${test}.${testset_cfg}.log
                    echo
                    echo "============ $AOS_EXPERIMENT_NAME | $AOS_TEST_NAME | $testset_cfg ============"
                    echo "Test Set Configuration: $testset_cfg" | sed -e 's/_/=/g; s/\./, /g' | tee $testlog
                    echo "AOS Experiment Environment:" >> $testlog
                    env | fgrep AOS_ 2>&1 >> $testlog
                    echo "Running script: " $AOS_REPO_ROOT/experiments/$experiment/$test/scripts/run/run-*.slurm >> $testlog
                    $AOS_REPO_ROOT/experiments/$experiment/$test/scripts/run/run-*.slurm 2>&1 | tee --append $testlog
                done
                cd $AOS_JOB_WORKDIR

            done
        done
    done
done
