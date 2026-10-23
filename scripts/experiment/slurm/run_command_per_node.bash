#!/bin/bash

cmdargs="$*"

srun --ntasks-per-node=1 --label $cmdargs | sort -g
