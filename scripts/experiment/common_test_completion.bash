# bash
#
# DESCRIPTION: Performs completion actions common to all test runs. 
#
# USAGE: source from SLURM job script
#
# ARGS: none
#
# ENVIRONMENT:
# - USES
#     AOS_EXPERIMENT_NAME        - experiment name
#     AOS_TEST_NAME              - test name (within experiment)
#     AOS_TEST_RUN_FINI_COMMANDS - optional: array of commands to run at test finalization
#     AOS_TEST_RUN_EXIT_ON_ERROR - optional: exit when error during run detected

# run finalization commands if present
if [ -n "$AOS_TEST_RUN_FINI_COMMANDS" ]; then
    for cmd in "${AOS_TEST_RUN_FINI_COMMANDS[@]}"; do
        echo "Running ${AOS_EXPERIMENT_NAME}-${AOS_TEST_NAME} test finalization command: $cmd"
        $cmd
    done
fi

# check for test run error and use it as exit code
exit ${AOS_TEST_CLIENT_RESULT:-0}
