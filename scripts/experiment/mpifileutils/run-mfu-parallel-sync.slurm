#!/bin/bash -l
#
# DESCRIPTION: Performs a parallel copy using dsync from mpiFileUtils.
#
# USAGE: execute from within SLURM job
#
# ARGS: none
#
# ENVIRONMENT:
# - USES
#     AOS_REPO_ROOT              - root directory of aos-storage-evals repo
#     AOS_EXPERIMENT_NAME        - experiment name
#     AOS_TEST_NAME              - test name (within experiment)
#     AOS_JOB_WORKDIR            - working directory for job
#     AOS_SOURCE                 - source file or directory
#     AOS_TARGET                 - target file or directory
#     AOS_CLIENT_MPI             - (optional) MPI implementation to use
#     AOS_IO_BLOCK_SIZE   - (optional) per-process sequential data chunk size
#     AOS_IO_REQUEST_SIZE - (optional) data buffer size for individual IOPs
#     AOS_MFU_DSYNC_EXECUTABLE   - (optional) path to mpiFileUtils dsync executable
# - DEFINES
#     AOS_CLIENT_COMMAND         - full command to run for ior client process

# perform common test setup actions
source $AOS_REPO_ROOT/scripts/experiment/common_test_setup.bash

# construct dsync command line
mfu_dsync_exe_path=${AOS_MFU_DSYNC_EXECUTABLE:-"dsync"}
mfu_dsync_target=$AOS_TARGET
mfu_dsync_source=$AOS_SOURCE

# dsync options: use O_DIRECT, don't modify atime, don't follow symlinks, ignore extended attrs
mfu_dsync_options="--direct --open-noatime --no-dereference --xattrs none"
if [ -n "$AOS_IO_BLOCK_SIZE" ]; then
    mfu_dsync_options+=" --chunksize $AOS_IO_BLOCK_SIZE"
fi
if [ -n "$AOS_IO_REQUEST_SIZE" ]; then
    mfu_dsync_options+=" --bufsize $AOS_IO_REQUEST_SIZE"
fi
mfu_dsync_command="$mfu_dsync_exe_path --progress 30 $mfu_dsync_options $mfu_dsync_source $mfu_dsync_target"

export AOS_CLIENT_COMMAND=$mfu_dsync_command

# run the parallel copy
env | fgrep AOS_ | sort > $AOS_TEST_RUN_CFG_DIR/env.aos
echo "Running mpiFileUtils dsync test"
launcher=${AOS_CLIENT_MPI:-slurm}
if [ "$launcher" == "slurm" ]; then
    source $AOS_REPO_ROOT/scripts/experiment/slurm/run_client_parallel.bash
elif [ "$launcher" == "mpich" ]; then
    source $AOS_REPO_ROOT/scripts/experiment/slurm/run_client_parallel_mpich.bash
elif [ "$launcher" == "openmpi" ]; then
    source $AOS_REPO_ROOT/scripts/experiment/slurm/run_client_parallel_ompi.bash
fi
echo

# perform common test completion actions
source $AOS_REPO_ROOT/scripts/experiment/common_test_completion.bash
