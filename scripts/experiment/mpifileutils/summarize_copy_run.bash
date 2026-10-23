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

copy_line=$(fgrep ' Copy rate: ' $runlog | sed -e 's/(//g; s/)//g')
update_line=$(fgrep ' Updated ' $runlog | tail -n 1 | sed -e 's/(//g; s/)//g')
rate_line=$(fgrep ' Rate: ' $runlog | sed -e 's/(//g; s/)//g')

if [[ -n "$copy_line" && -n "$update_line" && -n "$rate_line" ]]; then
    total_items=$(echo $update_line | awk '{print $3}')
    total_bytes=$(echo $rate_line | awk '{print $5}')
    total_time=$(echo $rate_line | awk '{print $8}')
    total_bw=$(echo $rate_line | awk '{print $5/$8}')

    copy_time=$(echo $copy_line | awk '{print $9}')
    copy_bw=$(echo $copy_line | awk '{print $6/$9}')

    update_time=$(echo $update_line | awk '{print $6}')
    update_rate=$(echo $update_line | awk '{print $8}')

    create_time=$( echo "scale=3; $total_time - ($copy_time + $update_time)" | bc )
    create_rate=$( echo "scale=3; $total_items / $create_time" | bc -l )
fi

if [ $print_human -eq 1 ]; then
    echo "CREATE ENTRIES: $total_items items in $create_time seconds ($create_rate items/sec)"
    echo "DATA COPY: $total_bytes bytes in $copy_time seconds ($copy_bw bytes/sec)"
    echo "METADATA UPDATE: $total_items items in $update_time seconds ($update_rate items/sec)"
    echo "TOTAL: $total_items ($total_bytes bytes) in $total_time seconds ($total_bw bytes/sec)"
elif [ $print_csv -eq 1 ]; then
    if [ $print_columns -eq 1 ]; then
        echo "total_copy_bytes,total_copy_time,create_time,create_rate,data_copy_time,data_copy_bandwidth,metadata_update_time,metadata_update_rate"
    else
        echo "$total_bytes,$total_time,$create_time,$create_rate,$copy_time,$copy_bw,$update_time,$update_rate"
    fi
fi
