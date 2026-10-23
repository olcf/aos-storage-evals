#!/bin/bash

# bash program to use dd on a single node or within a parallel MPI app to generate random-data files of uniform size within a target directory

n_ranks=${OMPI_COMM_WORLD_SIZE:-1}
my_rank=${OMPI_COMM_WORLD_RANK:-0}

if [ $# -ne 4 ]; then
    if [ $my_rank -eq 0 ]; then
        echo "USAGE ERROR: [$my_rank of $n_ranks] $0 <target-dir> <#files> <file-size-in-bytes> <block-size-in-bytes>"
    fi
    exit 1
fi

target_dir=$1
n_files=$2
file_sz=$3
block_sz=$4

if [ ! -d $target_dir ]; then
    if [ $my_rank -eq 0 ]; then
        echo "ERROR: [$my_rank of $n_ranks] $0 <target-dir> $target_dir does not exist"
    fi
    exit 1
fi

block_cnt=$(( $file_sz / $block_sz ))

start_ndx=$(( 1 + ($my_rank * $n_files) ))
end_ndx=$(( $start_ndx + $n_files - 1 ))

start_time=$(date +'%s')
for f in `seq $start_ndx $end_ndx`; do
    dd if=/dev/urandom of=$target_dir/f_$f bs=$block_sz count=$block_cnt >/dev/null 2>&1
done
end_time=$(date +'%s')
elapsed=$(( $end_time - $start_time ))

fps=$(( $n_files / $elapsed ))
bw=$(( $n_files * ($file_sz / 1024) / $elapsed )) 
echo "[$my_rank of $n_ranks] processed $fps files/second (effective bandwidth: $bw KiB/s)"
