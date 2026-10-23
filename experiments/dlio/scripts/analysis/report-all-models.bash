#!/bin/bash
experiment="dlio"

need_header=1
if [[ "$1" == '-o' && -n "$2" ]]; then
    output_csv=$2
    echo >&2 "INFO: Using output file $output_csv"
    if [ -f $output_csv ]; then
        # append to output file if it exists
        need_header=0
        exec >>$output_csv
    else
        exec >$output_csv
    fi 
    shift
    shift
fi

results_dir=${1:-$PWD}

exp_results_dir=$results_dir/$experiment

if [ ! -d $results_dir ]; then
    echo "ERROR: Results directory $results_dir not found!"
    echo "USAGE: $0 [/path/to/results]" 
    exit 1
elif [ ! -d $exp_results_dir ]; then
    echo "ERROR: No results for experiment $experiment found in $results_dir!"
    echo "USAGE: $0 [/path/to/results]" 
    exit 1
fi

echo >&2 "INFO: Using results directory $results_dir"

# report these tests in this order
tests="unet3d resnet50 cosmoflow"
testset=$(echo $tests | sed -e 's/ /-/g')

node_counts="4 8 12 16"
procs_per_node="6"

# iterate over number of client nodes
for n_nodes in $node_counts; do

    # iterate over number of processes per client node
    for ppn in $procs_per_node; do

        # report all experiments using this config
        testset_cfg="NODES_${n_nodes}.PPN_${ppn}"
        echo >&2 "INFO: Processing: $experiment - $testset_cfg"
        
        exp_runlogs=$exp_results_dir/$testset/$testset_cfg
        if [ -d $exp_runlogs ]; then
            pushd $exp_runlogs >/dev/null
            for exp_dir in */exp.*/ ; do
                plat=$(dirname $exp_dir)
                [[ "$plat" == '*' ]] && break
                pushd $exp_dir >/dev/null
                exp_stamp=$(basename $exp_dir | sed -e 's|exp\.||;s|/$||')
                echo >&2 "INFO:     Experiment: $plat - $exp_stamp"
                header_line=""
                if [ $need_header -eq 1 ]; then
                    header_line="#platform,node_count,processes_per_node,experiment_timestamp"
                    need_header=0
                fi
                exp_report="${plat},${n_nodes},${ppn},${exp_stamp}"
                for test in $tests; do
                    report_script=$AOS_REPO_ROOT/experiments/$experiment/$test/scripts/analysis/report-${test}.bash
                        
                    if [ -n "$header_line" ]; then
                        test_header=$($report_script -C $test)
                        header_line+=",$test_header"
                    fi
                        
                    testlog=${experiment}-${test}.${testset_cfg}.log
                    if [ -f $testlog ]; then
                        test_report=$($report_script $test $testlog)
                        exp_report+=",$test_report"
                    else
                        # use empty data
                        exp_report+=",,,"
                    fi
                done
                [ -n "$header_line" ] && echo $header_line
                echo "$exp_report" 
                popd >/dev/null # exp_dir
            done
            popd >/dev/null # exp_runlogs
        fi
    done
done
