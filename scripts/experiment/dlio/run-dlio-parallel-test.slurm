#!/bin/bash -l
#
# DESCRIPTION: Generates an dlio configuration file for the current experiment+test
# config and runs dlio in the data parallel MPI mode.
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
#     AOS_CLIENT_COMMAND         - full command to run for dlio client process
#     AOS_TEST_RUN_STAMP         - timestamp when this run script was started
#     AOS_TEST_CONFIG_LOG        - file where test configuration settings should be captured

# perform common test setup actions
source $AOS_REPO_ROOT/scripts/experiment/common_test_setup.bash

# get dlio configuration
dliocfg_name=${AOS_TEST_NAME}
dliocfg_test_cfg=$AOS_REPO_TEST_DIR/scripts/config/$AOS_CLIENT_CONFIG
dliocfg_platform_cfg=$AOS_REPO_TEST_DIR/scripts/config/${AOS_PLATFORM_SERVER}.dlio.cfg

if [ ! -f $dliocfg_test_cfg ]; then
    echo "ERROR: missing dlio configuration file: $dliocfg_test_cfg"
    exit 1
fi
source $dliocfg_test_cfg
[ -f $dliocfg_platform_cfg ] && source $dliocfg_platform_cfg

# construct dlio client command line
dlio_exe_path=${AOS_DLIO_EXECUTABLE:-"dlio_benchmark"}
dlio_cmd_options=""
[ -n "$dlio_configs_dir" ] && dlio_cmd_options+=" --config-dir $dlio_configs_dir"
if [ -z "$dlio_workload" ]; then # workload is mandatory arg
    echo "ERROR: missing 'dlio_workload' configuration setting"
    exit 1
else
    dlio_cmd_options+=" workload=$dlio_workload"
fi
[ -n "$dlio_generate" ]   && dlio_cmd_options+=" ++workload.workflow.generate_data=$dlio_generate"
[ -n "$dlio_train" ]      && dlio_cmd_options+=" ++workload.workflow.train=$dlio_train"
[ -n "$dlio_checkpoint" ] && dlio_cmd_options+=" ++workload.workflow.checkpoint=$dlio_checkpoint"
[ -n "$dlio_data_dir" ]   && dlio_cmd_options+=" ++workload.dataset.data_folder=$dlio_data_dir"

dlio_client_command="$dlio_exe_path $dlio_cmd_options"

export AOS_CLIENT_COMMAND=$dlio_client_command

# start the servers, run the client, then stop the servers
env | fgrep AOS_ | sort > $AOS_TEST_RUN_CFG_DIR/env.aos
echo "Running dlio test"
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
