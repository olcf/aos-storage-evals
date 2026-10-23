#!/bin/bash
experiment="large-file"

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

# report test results in this order
tests="copy read remove"
testset=$(echo $tests | sed -e 's/ /-/g')

node_counts="2 4 8 12 16"
procs_per_node="24 48"

KIB=1024
MIB=1048576
GIB=$(( $KIB * $MIB ))

file_sizes_gib="384 768 1536 3072 6144"
io_sizes="$((32 * $MIB)) $((64 * $MIB)) $((128 * $MIB)) $((256 * $MIB))"

# iterate over number of client nodes
for n_nodes in $node_counts; do

    # iterate over number of processes per client node
    for ppn in $procs_per_node; do

        # iterate over target file sizes
        for file_sz_gib in $file_sizes_gib; do
            file_sz=$(( $file_sz_gib * $GIB ))

            # iterate over I/O request sizes
            for io_req_sz in $io_sizes; do
                io_req_sz_mib=$(( $io_req_sz / $MIB ))

                # report all experiments using this config
                testset_cfg="NODES_${n_nodes}.PPN_${ppn}.FSZ_${file_sz_gib}GiB.IOSZ_${io_req_sz_mib}MiB"
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
                            header_line="#platform,node_count,processes_per_node,file_size,io_request_size,experiment_timestamp"
                            need_header=0
                        fi
                        exp_report="${plat},${n_nodes},${ppn},${file_sz},${io_req_sz},${exp_stamp}"
                        for test in $tests; do
                            testlog=${experiment}-${test}.${testset_cfg}.log
                            if [ -f $testlog ]; then
                                report_script=$AOS_REPO_ROOT/experiments/$experiment/$test/scripts/analysis/report-${test}.bash
                                if [ -n "$header_line" ]; then
                                    test_header=$($report_script -C $testlog)
                                    header_line+=",$test_header"
                                fi
                                test_report=$($report_script $testlog)
                                exp_report+=",$test_report"
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
    done
done
