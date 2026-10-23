#!/bin/bash -l
#
# DESCRIPTION: Runs file-stress-test for the current experiment+test config
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
#     AOS_CLIENT_COMMAND         - full command to run for fst client process

# perform common test setup actions
source $AOS_REPO_ROOT/scripts/experiment/common_test_setup.bash

# get fst configuration file and construct file-stress-test command line
fstcfg_name=${AOS_TEST_NAME}
fstcfg_test_cfg=$AOS_REPO_TEST_DIR/scripts/config/$AOS_CLIENT_CONFIG
fstcfg_platform_cfg=$AOS_REPO_TEST_DIR/scripts/config/${AOS_PLATFORM_SERVER}.fst.cfg

fstcfg_in=$AOS_TEST_RUN_CFG_DIR/${fstcfg_name}.fst.cfg
cp $fstcfg_test_cfg $fstcfg_in
[ -f $fstcfg_platform_cfg ] && cat $fstcfg_platform_cfg >> $fstcfg_in

echo "Generating file-stress-test command from client config ($fstcfg_in)"
source $AOS_REPO_ROOT/scripts/experiment/fst/generate_fst_command.bash $fstcfg_in

# start the servers, run the client, then stop the servers
env | fgrep AOS_ | sort > $AOS_TEST_RUN_CFG_DIR/env.aos
echo "Running file-stress-test"
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
