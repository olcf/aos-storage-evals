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

walk_line=$(fgrep ' Walked ' $runlog | tail -n 1 | sed -e 's/(//g; s/)//g')
rem_line=$(fgrep ' Removed ' $runlog | tail -n 1 | sed -e 's/(//g; s/)//g')

if [[ -n "$walk_line" && -n "$rem_line" ]]; then
    total_items=$(echo $walk_line | awk '{print $3}')

    walk_time=$(echo $walk_line | awk '{print $6}')
    walk_rate=$(echo $walk_line | awk '{print $8}')

    rem_time=$(echo $rem_line | awk '{print $6}')
    rem_rate=$(echo $rem_line | awk '{print $8}')
fi

if [ $print_human -eq 1 ]; then
    echo "WALK: $total_items items in $walk_time seconds ($walk_rate items/sec)"
    echo "REMOVE: $total_items items in $rem_time seconds ($rem_rate items/sec)"
elif [ $print_csv -eq 1 ]; then
    if [ $print_columns -eq 1 ]; then
        echo "walk_time,walk_rate,remove_time,remove_rate"
    else
        echo "$walk_time,$walk_rate,$rem_time,$rem_rate"
    fi
fi
