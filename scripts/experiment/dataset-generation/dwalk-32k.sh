#!/bin/bash

# uses mpiFileUtils dwalk to generate a MFU list file for each dataset that can be used as input to other tools
for g in 1 8 16; do
    mpirun --hostfile $AOS_PROJECT_DIR/quokka.hostfile -np 32 --map-by node $AOS_PROJECT_DIR/x86_64/bin/dwalk.quokka.ompi-daos26 --output 32k/32k.dataset.${g}GiB.mfu-list 32k/32k.dataset.${g}GiB
done
