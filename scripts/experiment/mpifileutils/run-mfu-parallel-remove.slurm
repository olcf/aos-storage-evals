#!/bin/bash -l
#
# DESCRIPTION: Performs a parallel remove using drm from mpiFileUtils.
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
#     AOS_TARGET                 - target file/directory to remove
#     AOS_MFU_DRM_EXECUTABLE     - (optional) path to mpiFileUtils drm executable
#     AOS_MFU_INPUT_LIST_FILE    - (optional) mpiFileUtils list file containing removal target(s)
# - DEFINES
#     AOS_CLIENT_COMMAND         - full command to run for ior client process

# perform common test setup actions
source $AOS_REPO_ROOT/scripts/experiment/common_test_setup.bash

# construct drm command line
mfu_drm_exe_path=${AOS_MFU_DRM_EXECUTABLE:-"drm"}
mfu_drm_target=$AOS_TARGET
mfu_drm_options="--lite" # don't stat entries during target directory walk
if [[ -e $AOS_TARGET || $AOS_TARGET =~ ^"daos://" ]]; then
    # for directories, check for mpifileutils listing
    mfu_drm_targ_list=${AOS_MFU_INPUT_LIST_FILE:-"${AOS_TARGET}.mfu-list"}
    if [ -d $AOS_TARGET -a -f $mfu_drm_targ_list ]; then
        mfu_drm_target="--input $mfu_drm_targ_list"
    fi
else
    # try workaround for fio-created datasets that use the target name as a prefix
    name_match_arg="--name --match '^$(basename $AOS_TARGET).*'"
    mfu_drm_target="$name_match_arg $(dirname $AOS_TARGET)/"
fi

mfu_drm_command="$mfu_drm_exe_path --progress 30 $mfu_drm_options $mfu_drm_target"
export AOS_CLIENT_COMMAND=$mfu_drm_command

# run the parallel remove
env | fgrep AOS_ | sort > $AOS_TEST_RUN_CFG_DIR/env.aos
echo "Running mpiFileUtils drm test"
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
