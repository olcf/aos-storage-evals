#!/bin/bash -l
#
# DESCRIPTION: Performs a parallel copy using dcp from mpiFileUtils.
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
#     AOS_MFU_DCP_EXECUTABLE     - (optional) path to mpiFileUtils dcp executable
# - DEFINES
#     AOS_CLIENT_COMMAND         - full command to run for ior client process

# perform common test setup actions
source $AOS_REPO_ROOT/scripts/experiment/common_test_setup.bash

# import platform-specific mfu-dcp config
mfudcp_platform_cfg=$AOS_REPO_TEST_DIR/scripts/config/${AOS_PLATFORM_SERVER}.mfu-dcp.cfg
[ -f $mfudcp_platform_cfg ] && source $mfudcp_platform_cfg

# construct dcp command line
mfu_dcp_exe_path=${AOS_MFU_DCP_EXECUTABLE:-"dcp"}
mfu_dcp_target=$AOS_TARGET
mfu_dcp_source=$AOS_SOURCE
if [ -d $AOS_SOURCE ]; then
    # for directories, check for mpifileutils listing
    mfu_dcp_src_list=${AOS_MFU_INPUT_LIST_FILE:-"${AOS_SOURCE}.mfu-list"}
    if [ -f $mfu_dcp_src_list ]; then
        mfu_dcp_source="--input $mfu_dcp_src_list $AOS_SOURCE"
    fi  
fi

# dcp options: use O_DIRECT, don't modify atime, don't follow symlinks, ignore extended attrs
mfu_dcp_options="--direct --no-dereference --xattrs none"
if [ -n "$AOS_IO_BLOCK_SIZE" ]; then
    mfu_dcp_options+=" --chunksize $AOS_IO_BLOCK_SIZE"
fi
if [ -n "$AOS_IO_REQUEST_SIZE" ]; then
    mfu_dcp_options+=" --bufsize $AOS_IO_REQUEST_SIZE"
fi
mfu_dcp_command="$mfu_dcp_exe_path --progress 30 $mfu_dcp_options $mfu_dcp_source $mfu_dcp_target"

export AOS_CLIENT_COMMAND=$mfu_dcp_command

# run the parallel copy
env | fgrep AOS_ | sort > $AOS_TEST_RUN_CFG_DIR/env.aos
echo "Running mpiFileUtils dcp test"
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
