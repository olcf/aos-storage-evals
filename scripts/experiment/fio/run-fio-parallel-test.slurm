#!/bin/bash -l
#
# DESCRIPTION: Generates a fio job for the current experiment+test config and runs the
# fio job using client-server mode. 
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
#     AOS_CLIENT_COMMAND         - full command to run for local client control process
#     AOS_CLIENT_SVC_COMMAND     - full command to run on each job node for client service
#     AOS_TEST_RUN_STAMP         - timestamp when this run script was started
#     AOS_TEST_CONFIG_LOG        - file where test configuration settings should be captured

# perform common test setup actions
source $AOS_REPO_ROOT/scripts/experiment/common_test_setup.bash

# generate fio job file
fiojob_name=${AOS_TEST_NAME}
fiocfg_test_cfg=$AOS_REPO_TEST_DIR/scripts/config/$AOS_CLIENT_CONFIG
fiocfg_platform_cfg=$AOS_REPO_TEST_DIR/scripts/config/${AOS_PLATFORM_SERVER}.fio.cfg

fiojob_in=$AOS_TEST_RUN_CFG_DIR/${fiojob_name}.fio.in
cp $fiocfg_test_cfg $fiojob_in
[ -f $fiocfg_platform_cfg ] && cat $fiocfg_platform_cfg >> $fiojob_in

fiojob_file=$AOS_TEST_RUN_CFG_DIR/${fiojob_name}.fio
echo "Generating fio job file from client config ($fiojob_in)"
$AOS_REPO_ROOT/scripts/experiment/fio/generate_fio_config.bash $fiojob_in $fiojob_file
if [ ! -f $fiojob_file ]; then
    echo "ERROR: failed to generate fio job file from $fiojob_in"
    exit 1
fi

# construct fio client and service command lines
fio_exe_path=${AOS_FIO_EXECUTABLE:-"fio"}
fiojob_out=$AOS_TEST_RUN_LOG_DIR/${fiojob_name}.fio.out
fio_service_command="$fio_exe_path --server --alloc-size=1048576"
fio_client_command="$fio_exe_path --output=$fiojob_out --output-format=terse --client=$AOS_JOB_HOST_FILE $fiojob_file"

export AOS_CLIENT_COMMAND=$fio_client_command
export AOS_CLIENT_SVC_COMMAND=$fio_service_command

# start the servers, run the client, then stop the servers
env | fgrep AOS_ | sort > $AOS_TEST_RUN_CFG_DIR/env.aos
echo "Running fio job"
source $AOS_REPO_ROOT/scripts/experiment/slurm/run_client_service.bash
echo

# parse fio client output
echo "Processing fio output file ($fiojob_out)"
terse_line=$( fgrep 'All clients' $fiojob_out | tail -n1 )
if [ -z "$terse_line" ]; then
    # no aggregate line found, look for last terse line
    terse_line=$( fgrep '3;fio' $fiojob_out | tail -n1 )
fi
if [ -n "$terse_line" ]; then
    # capture fio results as bash variables
    eval $( $AOS_REPO_ROOT/scripts/experiment/fio/parser/fio_terse_to_bash.bash "$terse_line" )
    echo "- read performance is $read_bandwidth_kb KiB/sec ($read_iops IOPS)"
    echo "- write performance is $write_bandwidth_kb KiB/sec ($write_iops IOPS)"
    echo
    # capture fio results in csv file
    fiojob_csv=$AOS_TEST_RUN_LOG_DIR/${fiojob_name}.fio.csv
    echo "Generating fio results csv file ($fiojob_csv)"
    $AOS_REPO_ROOT/scripts/experiment/fio/parser/fio_terse_to_csv.bash "$terse_line" > $fiojob_csv
fi

# perform common test completion actions
source $AOS_REPO_ROOT/scripts/experiment/common_test_completion.bash
