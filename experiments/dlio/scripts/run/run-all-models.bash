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

# set target name
export AOS_TARGET=$target_dir

# get AOS_JOB_SIZE, AOS_JOB_HOST_LIST, and AOS_JOB_HOST_FILE
source $AOS_REPO_ROOT/scripts/experiment/slurm/get_slurm_job_hosts.bash

experiment="dlio"
export AOS_EXPERIMENT_NAME=$experiment

# run these tests in this order
tests="resnet50 cosmoflow"
testset=$(echo $tests | sed -e 's/ /-/g')

node_counts=${AOS_EXPERIMENT_NODE_COUNTS:-"4 8 12 16"}
procs_per_node="6" # NOTE: models use 8 I/O threads per process, so 48 threads per node

# iterate over number of client nodes
for n_nodes in $node_counts; do

    # skip node counts that do not fit within current job
    [ $n_nodes -gt $AOS_JOB_SIZE ] && continue

    export AOS_CLIENT_NODES=$n_nodes

    # iterate over number of processes per client node
    for ppn in $procs_per_node; do
        export AOS_CLIENT_PROCS_PER_NODE=$ppn

        # using this config, run the sequenced test set within a single experiment
        testset_cfg="NODES_${n_nodes}.PPN_${ppn}"
        runstamp=$(date +'exp.%Y%m%d_%H%M%S')
        export AOS_EXPERIMENT_RUN_STAMP=$runstamp

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
