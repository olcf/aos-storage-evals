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

result_line=$(fgrep 'RESULT: ' $runlog | sed -e 's/(//g; s/)//g; s/,//g')

if [ -n "$result_line" ]; then
    file_rate=$(echo $result_line | awk '{print $2}')
    nprocs=$(echo $result_line | awk '{print $8}')
    min_process_rate=$(echo $result_line | awk '{print $10}' | cut -f 2 -d '=')
    max_process_rate=$(echo $result_line | awk '{print $11}' | cut -f 2 -d '=')
    avg_process_rate=$(echo $result_line | awk '{print $12}' | cut -f 2 -d '=')
fi

if [ $print_human -eq 1 ]; then
    echo "File Processing Rate: $file_rate files/sec using $nprocs processes"
    echo "Per-Process Rates: Min(${min_process_rate}) Max(${max_process_rate}) Avg(${avg_process_rate})"
elif [ $print_csv -eq 1 ]; then
    if [ $print_columns -eq 1 ]; then
        echo "file_rate_shared,min_process_rate_shared,max_process_rate_shared,avg_process_rate_shared"
    else
        echo "$file_rate,$min_process_rate,$max_process_rate,$avg_process_rate"
    fi
fi
