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

model=$1
runlog=${2-"log_not_provided"}

usage_msg="USAGE: $0 <model> <run-log>"

if [ -z "$model" ]; then
    echo >&2 "USAGE ERROR: DLIO model name not provided!"
    echo >&2 "$usage_msg"
    exit 1
fi

if [ $print_columns -eq 1 ]; then
    echo "${model}_training_device_util,${model}_training_sample_rate,${model}_training_bandwidth"
    exit 0
fi

if [ ! -f $runlog ]; then
    echo >&2 "USAGE ERROR: run log file $runlog not found!"
    echo >&2 "$usage_msg"
    exit 1
fi

metric_util=$(fgrep '[METRIC] Training Accelerator Utilization' $runlog)
metric_rate=$(fgrep '[METRIC] Training Throughput' $runlog)
metric_bw=$(fgrep '[METRIC] Training I/O Throughput' $runlog)

if [ -n "$metric_util" ]; then
    acc_util=$(echo $metric_util | awk '{print $7}')
fi

if [ -n "$metric_rate" ]; then
    train_rate=$(echo $metric_rate | awk '{print $5}')
fi

if [ -n "$metric_util" ]; then
    train_bw_mib=$(echo $metric_bw | awk '{print $6}')
    train_bw=$(echo "scale=3; $train_bw_mib * 1048576" | bc)
fi

if [ $print_human -eq 1 ]; then
    echo "Training Results for $model: utilization($acc_util), rate($train_rate samples/sec), bandwidth($train_bw_mib MiB/sec)"
elif [ $print_csv -eq 1 ]; then
    echo "$acc_util,$train_rate,$train_bw"
fi
