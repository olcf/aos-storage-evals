# bash
#
# DESCRIPTION: Performs setup actions common to all test runs. 
#
# USAGE: source from SLURM job script
#
# ARGS: none
#
# ENVIRONMENT:
# - USES
#     AOS_REPO_ROOT              - root directory of aos-storage-evals repo
#     AOS_EXPERIMENT_NAME        - experiment name
#     AOS_TEST_NAME              - test name (within experiment)
#     AOS_JOB_WORKDIR            - optional: working directory for job (current directory if not set)
#     AOS_EXPERIMENT_RUN_DIR     - optional: unique directory for experiment that will contain test runs (current directory if not set)
# - DEFINES
#     AOS_TEST_RUN_STAMP         - timestamp when this run was started
#     AOS_TEST_RUN_DIR           - unique timestamped directory holding test run products
#     AOS_TEST_RUN_CFG_DIR       - test run subdirectory containing configs
#     AOS_TEST_RUN_LOG_DIR       - test run subdirectory containing logs
#     AOS_TEST_CONFIG_LOG        - file where test configuration settings should be captured
#     AOS_TEST_RUN_INIT_COMMANDS - array of commands to run at test initialization (NOTE: typically set by imported test config)    
#     AOS_TEST_RUN_FINI_COMMANDS - array of commands to run at test finalization (NOTE: typically set by imported test config)    

if [ -z "$AOS_REPO_ROOT" ]; then
    echo "CONFIG ERROR: AOS_REPO_ROOT is not set!"
    exit 1
elif [ -z "$AOS_EXPERIMENT_NAME" ]; then
    echo "CONFIG ERROR: AOS_EXPERIMENT_NAME is not set!"
    exit 1
elif [ -z "$AOS_TEST_NAME" ]; then
    echo "CONFIG ERROR: AOS_TEST_NAME is not set!"
    exit 1
fi

export AOS_TEST_RUN_STAMP=$(date +'test.%Y%m%d_%H%M%S')
[[ -n "$AOS_SCRIPT_DEBUG" && $AOS_SCRIPT_DEBUG -eq 1 ]] && echo >&2 "DEBUG: AOS_TEST_RUN_STAMP = $AOS_TEST_RUN_STAMP"

exp_scripts=$AOS_REPO_ROOT/scripts/experiment

if [ -n "$AOS_JOB_WORKDIR" ]; then
    if [ "$PWD" != "$AOS_JOB_WORKDIR" ]; then
        cd $AOS_JOB_WORKDIR || ( echo "ERROR: could not change directory to $AOS_JOB_WORKDIR"; exit 1; )
    fi
else
    export AOS_JOB_WORKDIR=$PWD
fi

# get AOS_JOB_SIZE, AOS_JOB_HOST_LIST, and AOS_JOB_HOST_FILE
source $exp_scripts/slurm/get_slurm_job_hosts.bash

# create subdirectories for various test products
export AOS_TEST_RUN_DIR=${AOS_EXPERIMENT_RUN_DIR:-$PWD}/${AOS_TEST_NAME}-${AOS_TEST_RUN_STAMP}
mkdir -p $AOS_TEST_RUN_DIR/{config,logs} || ( echo "ERROR: could not create subdirectories for run config and logs"; exit 1; )
export AOS_TEST_RUN_CFG_DIR=$AOS_TEST_RUN_DIR/config
export AOS_TEST_RUN_LOG_DIR=$AOS_TEST_RUN_DIR/logs

# get test configuration (and log it)
declare -a AOS_TEST_RUN_INIT_COMMANDS
declare -a AOS_TEST_RUN_FINI_COMMANDS
export AOS_TEST_CONFIG_LOG=$AOS_TEST_RUN_CFG_DIR/test_configs.log
source $exp_scripts/get_test_configuration.bash

# run init commands if present in test configuration
if [ -n "$AOS_TEST_RUN_INIT_COMMANDS" ]; then
    for cmd in "${AOS_TEST_RUN_INIT_COMMANDS[@]}"; do
        echo "Running ${AOS_EXPERIMENT_NAME}-${AOS_TEST_NAME} test initialization command: $cmd"
        $cmd
    done
fi
