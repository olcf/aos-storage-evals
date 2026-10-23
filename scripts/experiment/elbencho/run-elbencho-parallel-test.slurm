#!/bin/bash -l
#
# DESCRIPTION: Generates an elbencho configuration file for the current experiment+test
# config and runs elbencho using client-service mode. 
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
# - DEFINES
#     AOS_CLIENT_COMMAND         - full command to run for local client control process
#     AOS_CLIENT_SVC_COMMAND     - full command to run on each job node for client service

# perform common test setup actions
source $AOS_REPO_ROOT/scripts/experiment/common_test_setup.bash

# generate elbencho configuration file
ebcfg_name=${AOS_TEST_NAME}
ebcfg_test_cfg=$AOS_REPO_TEST_DIR/scripts/config/$AOS_CLIENT_CONFIG
ebcfg_platform_cfg=$AOS_REPO_TEST_DIR/scripts/config/${AOS_PLATFORM_SERVER}.elbencho.cfg

ebcfg_in=$AOS_TEST_RUN_CFG_DIR/${ebcfg_name}.elbencho.in
cp $ebcfg_test_cfg $ebcfg_in
[ -f $ebcfg_platform_cfg ] && cat $ebcfg_platform_cfg >> $ebcfg_in

ebcfg_hosts=$AOS_TEST_RUN_CFG_DIR/${ebcfg_name}.elbencho.hosts
if [[ -n "$AOS_CLIENT_NODES" && $AOS_CLIENT_NODES -lt $AOS_JOB_SIZE ]]; then
    head -n $AOS_CLIENT_NODES $AOS_JOB_HOST_FILE > $ebcfg_hosts
else
    cp $AOS_JOB_HOST_FILE $ebcfg_hosts
fi

ebcfg_file=$AOS_TEST_RUN_CFG_DIR/${AOS_TEST_NAME}.elbencho
echo "Generating elbencho config file from client config ($ebcfg_in)"
$AOS_REPO_ROOT/scripts/experiment/elbencho/generate_elbencho_config.bash $ebcfg_in $ebcfg_file
if [ ! -f $ebcfg_file ]; then
    echo "ERROR: failed to generate elbencho config file from $ebcfg_in"
    exit 1
else
    # if the config generation needs to update or set new AOS env vars, it will
    # create another file with .aosenv suffix that we can source
    [ -f ${ebcfg_file}.aosenv ] && source ${ebcfg_file}.aosenv
fi

# construct elbencho client and service command lines
elbencho_exe_path=${AOS_ELBENCHO_EXECUTABLE:-"elbencho"}
elbencho_out=$AOS_TEST_RUN_LOG_DIR/${ebcfg_name}.elbencho.out
elbencho_csv=$AOS_TEST_RUN_LOG_DIR/${ebcfg_name}.elbencho.csv
elbencho_service_command="$elbencho_exe_path --service --foreground"
elbencho_client_command="$elbencho_exe_path --resfile $elbencho_out --csvfile $elbencho_csv --hostsfile $ebcfg_hosts --configfile $ebcfg_file $AOS_TARGET"

export AOS_CLIENT_COMMAND=$elbencho_client_command
export AOS_CLIENT_SVC_COMMAND=$elbencho_service_command

# start the servers, run the client, then stop the servers
env | fgrep AOS_ | sort > $AOS_TEST_RUN_CFG_DIR/env.aos
echo "Running elbencho test"
source $AOS_REPO_ROOT/scripts/experiment/slurm/run_client_service.bash
echo

# perform common test completion actions
source $AOS_REPO_ROOT/scripts/experiment/common_test_completion.bash
