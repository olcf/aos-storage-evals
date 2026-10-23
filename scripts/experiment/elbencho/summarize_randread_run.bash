#!/bin/bash

print_csv=1
print_columns=0
print_human=0

if [[ "$1" == '-C' ]]; then
    print_columns=1
    shift
elif [[ "$1" == '-H' ]]; then
    print_human=1
    print_csv=0
    shift
fi

runlog=${1-"log_not_provided"}

if [ ! -f $runlog ]; then
    echo >&2 "USAGE ERROR: run log file $runlog not found!"
    echo >&2 "USAGE: $0 <run-log>"
    exit 1
fi

iops_vals=$(awk -v ORS=' ' '/IOPS/ {print $4}' $runlog)
bw_vals=$(awk -v ORS=' ' '/Throughput MiB/ {print $5}' $runlog)

if [ -n "$iops_vals" ]; then
    epoch1_iops=$(echo $iops_vals | cut -f 1 -d ' ')
    avg_epochk_iops=$( echo $iops_vals | cut -f 2- -d ' ' | awk -v RS=' ' '{sum+=$1} END{print sum/NR}')
fi

if [ -n "$bw_vals" ]; then
    epoch1_bw=$(echo $bw_vals | awk '{print ($1*1048576.0)}')
    avg_epochk_bw=$( echo $bw_vals | cut -f 2- -d ' ' | awk -v RS=' ' '{sum+=($1*1048576.0)} END{print sum/NR}')
fi

if [ $print_human -eq 1 ]; then
    echo 'Random Read IOPS: 1st(' $epoch1_iops ') kth(' $avg_epochk_iops ')'
    echo 'Random Read Bandwidth (bytes/sec): 1st(' $epoch1_bw ') kth(' $avg_epochk_bw ')'
elif [ $print_csv -eq 1 ]; then
    if [ $print_columns -eq 1 ]; then
        echo "randread_iops_epoch1,randread_iops_epochk_avg,randread_bandwidth_epoch1,randread_bandwidth_epochk_avg"
    else
        echo "$epoch1_iops,$avg_epochk_iops,$epoch1_bw,$avg_epochk_bw"
    fi
fi