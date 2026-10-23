#!/bin/bash

if [ $# -ne 2 ]; then
    echo "ERROR: source and/or target data directory not provided!"
    echo "USAGE: $0 <source-dir> <target-dir>"
    exit 1
fi

source_dir=$1
target_dir=$2

if [ -z "$AOS_REPO_ROOT" -o -z "$AOS_PLATFORM_SERVER" -o -z "$AOS_PLATFORM_CLIENT" ]; then
    echo "USAGE ERROR: Please set AOS_REPO_ROOT, AOS_PLATFORM_SERVER, and AOS_PLATFORM_CLIENT"
    exit 1
fi

export AOS_JOB_WORKDIR=$PWD

# get AOS_JOB_SIZE, AOS_JOB_HOST_LIST, and AOS_JOB_HOST_FILE
source $AOS_REPO_ROOT/scripts/experiment/slurm/get_slurm_job_hosts.bash

experiment="small-files-varied"
export AOS_EXPERIMENT_NAME=$experiment

# run these tests in this order
tests="copy read remove"
testset=$(echo $tests | sed -e 's/ /-/g')

node_counts=${AOS_EXPERIMENT_NODE_COUNTS:-"2 4 8 12 16"}
procs_per_node=${AOS_EXPERIMENT_PPN_COUNTS:-"24 48"}

KIB=1024
MIB=1048576
GIB=$(( $KIB * $MIB ))

file_counts="$((256 * $KIB)) $((512 * $KIB)) $MIB" 
file_sizes="$((32 * $KIB)) $MIB"

# iterate over number of client nodes
for n_nodes in $node_counts; do
    
    # skip node counts that do not fit within current job
    [ $n_nodes -gt $AOS_JOB_SIZE ] && continue

    export AOS_CLIENT_NODES=$n_nodes

    # iterate over number of processes per client node
    for ppn in $procs_per_node; do
        export AOS_CLIENT_PROCS_PER_NODE=$ppn

        # iterate over target dataset sizes (in terms of file count)
        for fcount in $file_counts; do
            export AOS_IO_FILE_COUNT=$fcount

            # iterate over file sizes
            for fsz in $file_sizes; do
                export AOS_IO_FILE_SIZE=$fsz
                export AOS_IO_REQUEST_SIZE=$fsz

                ds_sz_gib=$(( ($fcount * $fsz) / $GIB ))

                # source dataset for small-files-uniform copy uses only total size in name, but
                # is located in a subdirectory for the target file size ('32k' or '1m')
                fsz_name="1m"
                [ "$fsz" != "$MIB" ] && fsz_name="32k"
                export AOS_SOURCE=$source_dir/$experiment/$fsz_name/dataset.${ds_sz_gib}GiB

                # using this config, run the sequenced test set within a single experiment
                testset_cfg="NODES_${n_nodes}.PPN_${ppn}.FCNT_${fcount}.FSZ_${fsz_name}"
                runstamp=$(date +'exp.%Y%m%d_%H%M%S')
                export AOS_EXPERIMENT_RUN_STAMP=$runstamp

                # set target name using size and runstamp
                export AOS_TARGET=$target_dir/ds.$experiment.${fsz_name}-${ds_sz_gib}GiB.$runstamp
                
                exp_rundir=$AOS_JOB_WORKDIR/$experiment/$testset/$testset_cfg/$AOS_PLATFORM_SERVER/$runstamp
                mkdir -p $exp_rundir && cd $exp_rundir
                export AOS_EXPERIMENT_RUN_DIR=$PWD # this works even if prior directory creation fails
                for test in $tests; do
                    # only abort experiment if copy phase fails
                    if [ "$test" == "copy" ]; then
                        AOS_EXPERIMENT_ABORT_ON_TEST_ERROR=1
                    else
                        AOS_EXPERIMENT_ABORT_ON_TEST_ERROR=0
                    fi

                    export AOS_TEST_NAME=$test
                    testlog=${experiment}-${test}.${testset_cfg}.log
                    echo
                    echo "============ $AOS_EXPERIMENT_NAME | $AOS_TEST_NAME | $testset_cfg ============"
                    echo "Test Set Configuration: $testset_cfg" | sed -e 's/_/=/g; s/\./, /g' | tee $testlog
                    echo "AOS Experiment Environment:" >> $testlog
                    env | fgrep AOS_ 2>&1 >> $testlog
                    echo "Running script: " $AOS_REPO_ROOT/experiments/$experiment/$test/scripts/run/run-*.slurm >> $testlog
                    $AOS_REPO_ROOT/experiments/$experiment/$test/scripts/run/run-*.slurm 2>&1 | tee --append $testlog
                    test_rc=$?
                    if [ $test_rc -ne 0 ]; then
                        if [ ${AOS_EXPERIMENT_ABORT_ON_TEST_ERROR} -eq 1 ]; then
                            echo "EXPERIMENT ERROR: Aborting experiment due to prior test error!"
                            exit $test_rc
                        fi
                    fi
                done
                cd $AOS_JOB_WORKDIR

            done
        done
    done
done
