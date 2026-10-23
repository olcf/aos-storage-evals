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

experiment="32k-file-stress-test"
export AOS_EXPERIMENT_NAME=$experiment

# run these tests in this order
tests="shared_dir unique_client_dir"
testset=$(echo $tests | sed -e 's/ /-/g')

node_counts=${AOS_EXPERIMENT_NODE_COUNTS:-"4 8 12 16"}
procs_per_node=${AOS_EXPERIMENT_PPN_COUNTS:-"48"}
files_per_process="128 256 512 1024"

# iterate over number of client nodes
for n_nodes in $node_counts; do

    # skip node counts that do not fit within current job
    [ $n_nodes -gt $AOS_JOB_SIZE ] && continue

    export AOS_CLIENT_NODES=$n_nodes

    # iterate over number of processes per client node
    for ppn in $procs_per_node; do
        export AOS_CLIENT_PROCS_PER_NODE=$ppn
        total_procs=$(( $n_nodes * $ppn ))

        # iterate over number of processes per client node
        for fpp in $files_per_process; do
            export AOS_IO_FILE_COUNT=$fpp

            # using this config, run the sequenced test set within a single experiment
            fcount=$(( $total_procs * $fpp ))
            testset_cfg="NODES_${n_nodes}.PPN_${ppn}.FCNT_${fcount}.FSZ_32k"
            runstamp=$(date +'exp.%Y%m%d_%H%M%S')
            export AOS_EXPERIMENT_RUN_STAMP=$runstamp

            exp_rundir=$AOS_JOB_WORKDIR/$experiment/$testset/$testset_cfg/$AOS_PLATFORM_SERVER/$runstamp
            mkdir -p $exp_rundir && cd $exp_rundir
            export AOS_EXPERIMENT_RUN_DIR=$PWD # this works even if prior directory creation fails
            for test in $tests; do
                export AOS_TEST_NAME=$test

                # set target name
                export AOS_TARGET=$target_dir/ds.$test.32K_x_${fcount}.N${n_nodes}_P${total_procs}.$runstamp

                testlog=${experiment}-${test}.${testset_cfg}.log
                echo
                echo "============ $AOS_EXPERIMENT_NAME | $AOS_TEST_NAME | $testset_cfg ============"
                echo "Test Set Configuration: $testset_cfg" | sed -e 's/_/=/g; s/\./, /g' | tee $testlog
                echo "AOS Experiment Environment:" >> $testlog
                env | fgrep AOS_ 2>&1 >> $testlog
                echo "Running script: " $AOS_REPO_ROOT/experiments/$experiment/$test/scripts/run/run-fst-parallel-test.slurm >> $testlog
                $AOS_REPO_ROOT/experiments/$experiment/$test/scripts/run/run-fst-parallel-test.slurm 2>&1 | tee --append $testlog
            done
            cd $AOS_JOB_WORKDIR

        done
    done
done
