#!/bin/bash -l
#
# DESCRIPTION: Generates an ior configuration file for the current experiment+test
# config and runs ior using MPI mode.
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
#     AOS_CLIENT_CONFIG          - client config file for current test
#     AOS_JOB_WORKDIR            - working directory for job
# - DEFINES
#     AOS_JOB_NAME               - short name of job
#     AOS_CLIENT_COMMAND         - full command to run for ior client process
#     AOS_TEST_RUN_STAMP         - timestamp when this run script was started
#     AOS_TEST_CONFIG_LOG        - file where test configuration settings should be captured

# perform common test setup actions
source $AOS_REPO_ROOT/scripts/experiment/common_test_setup.bash

# generate ior configuration file
iorcfg_name=${AOS_TEST_NAME}
iorcfg_test_cfg=$AOS_REPO_TEST_DIR/scripts/config/$AOS_CLIENT_CONFIG
iorcfg_platform_cfg=$AOS_REPO_TEST_DIR/scripts/config/${AOS_PLATFORM_SERVER}.ior.cfg

iorcfg_in=$AOS_TEST_RUN_CFG_DIR/${iorcfg_name}.ior.in
cp $iorcfg_test_cfg $iorcfg_in
[ -f $iorcfg_platform_cfg ] && cat $iorcfg_platform_cfg >> $iorcfg_in

iorcfg_out=$AOS_TEST_RUN_CFG_DIR/${iorcfg_name}.ior
echo "Generating ior config file from client config ($iorcfg_in)"
$AOS_REPO_ROOT/scripts/experiment/ior/generate_ior_config.bash $iorcfg_in $iorcfg_out
if [ ! -f $iorcfg_out ]; then
    echo "ERROR: failed to generate ior config file from $iorcfg_in"
    exit 1
fi

# construct ior client and service command lines
ior_exe_path=${AOS_IOR_EXECUTABLE:-"ior"}
ior_options=""
[ -f ${iorcfg_out}.cliopt ] && ior_options+=$(cat ${iorcfg_out}.cliopt)
ior_client_command="$ior_exe_path $ior_options -f $iorcfg_out"

export AOS_CLIENT_COMMAND=$ior_client_command

# start the servers, run the client, then stop the servers
env | fgrep AOS_ | sort > $AOS_TEST_RUN_CFG_DIR/env.aos
echo "Running ior test"
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
