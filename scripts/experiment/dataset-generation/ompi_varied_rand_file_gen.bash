#!/bin/bash

# bash program to use dd on a single node or within a parallel MPI app to generate random-data files of varied size within a target directory

n_ranks=${OMPI_COMM_WORLD_SIZE:-1}
my_rank=${OMPI_COMM_WORLD_RANK:-0}

if [ $# -ne 3 ]; then
    if [ $my_rank -eq 0 ]; then
        echo "USAGE ERROR: [$my_rank of $n_ranks] $0 <target-dir> <#files-per-proc> <avg-file-size-in-bytes>"
    fi
    exit 1
fi

target_dir=$1
n_files=$2
avg_file_sz=$3

n_blocks=$(( avg_file_sz / 1024 ))
min_file_blocks=$(( $n_blocks / 2 ))
max_file_blocks=$(( $n_blocks * 2 ))

if [ ! -d $target_dir ]; then
    if [ $my_rank -eq 0 ]; then
        echo "ERROR: [$my_rank of $n_ranks] $0 <target-dir> $target_dir does not exist"
    fi
    exit 1
fi

start_ndx=$(( 1 + ($my_rank * $n_files) ))
end_ndx=$(( $start_ndx + $n_files - 1 ))
#echo "DEBUG: [$my_rank of $n_ranks] generating ${avg_file_sz}B files in [$start_ndx, $end_ndx]"

total_bytes=0
start_time=$(date +'%s')
for f in `seq $start_ndx $end_ndx`; do
    # use 1k size increments
    file_blocks=$(( $RANDOM % $max_file_blocks ))
    if [ $file_blocks -lt $min_file_blocks ]; then
        file_blocks=$min_file_blocks
    fi
    file_sz=$(( $file_blocks * 1024 ))
    total_bytes=$(( total_bytes + $file_sz ))
    #echo "DEBUG: [$my_rank of $n_ranks] generating file $f with size $file_sz"
    dd if=/dev/urandom of=$target_dir/f_$f bs=$file_sz count=1 >/dev/null 2>&1
done
end_time=$(date +'%s')
elapsed=$(( $end_time - $start_time ))
[ $elapsed -eq 0 ] && elapsed=1

fps=$(( $n_files / $elapsed ))
bw=$(( ($total_bytes / 1024) / $elapsed )) 
echo "[$my_rank of $n_ranks] processed $fps files/second (effective bandwidth: $bw KiB/s)"
