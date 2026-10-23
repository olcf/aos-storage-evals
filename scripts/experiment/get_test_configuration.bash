# bash
#
# DESCRIPTION: import all the relevant configuration settings (bash variables)
# that are relevant to the current experiment, test, and platforms
#
# USAGE: source from within bash test scripts
#
# ARGS: none
#
# ENVIRONMENT:
# - USES
#     AOS_REPO_ROOT                - absolute path to aos-storage-evals repo
#     AOS_PLATFORM_CLIENT          - client platform name
#     AOS_PLATFORM_SERVER          - server platform name
#     AOS_EXPERIMENT_NAME          - experiment name
#     AOS_TEST_NAME                - test name (within experiment)
#     AOS_TARGET                   - I/O target datatset
#     AOS_TEST_CONFIG_LOG          - optional file to log imported configuration settings
#     AOS_CLIENT_SOFTWARE          - name of client software used for test (app/benchmark name)
#     AOS_CLIENT_SOFTWARE_VERSION  - version of client software used for test
# - DEFINES
#     AOS_REPO_EXPERIMENT_DIR      - absolute path to experiment directory within repo
#     AOS_REPO_TEST_DIR            - absolute path to test directory within repo
#     AOS_KB, AOS_KIB              - kilobyte and kibibyte
#     AOS_MB, AOS_MIB              - megabyte and mebibyte
#     AOS_GB, AOS_GIB              - gigabyte and gibibyte
#     AOS_TB, AOS_TIB              - terabyte and tebibyte

export AOS_KB=1000
export AOS_KIB=1024
export AOS_MB=$(( $AOS_KB * 1000 ))
export AOS_MIB=$(( $AOS_KIB * 1024 ))
export AOS_GB=$(( $AOS_MB * 1000 ))
export AOS_GIB=$(( $AOS_MIB * 1024 ))
export AOS_TB=$(( $AOS_GB * 1000 ))
export AOS_TIB=$(( $AOS_GIB * 1024 ))

cfg_log=${AOS_TEST_CONFIG_LOG:-"/dev/null"}
function import_config {
    cfg_file=$1
    if [ -f $cfg_file ]; then
        set -x; source $cfg_file; set +x
    fi
} 2>>$cfg_log

if [ -z "$AOS_REPO_ROOT" ]; then
    echo "CONFIG ERROR: AOS_REPO_ROOT is not set!"
    exit 1
elif [ -z "$AOS_PLATFORM_CLIENT" ]; then
    echo "CONFIG ERROR: AOS_PLATFORM_CLIENT is not set!"
    exit 1
elif [ -z "$AOS_PLATFORM_SERVER" ]; then
    echo "CONFIG ERROR: AOS_PLATFORM_SERVER is not set!"
    exit 1
elif [ -z "$AOS_EXPERIMENT_NAME" ]; then
    echo "CONFIG ERROR: AOS_EXPERIMENT_NAME is not set!"
    exit 1
elif [ -z "$AOS_TEST_NAME" ]; then
    echo "CONFIG ERROR: AOS_TEST_NAME is not set!"
    exit 1
elif [ -z "$AOS_TARGET" ]; then
    echo "CONFIG ERROR: AOS_TARGET is not set!"
    exit 1
else
    AOS_REPO_EXPERIMENT_DIR=$AOS_REPO_ROOT/experiments/$AOS_EXPERIMENT_NAME
    AOS_REPO_TEST_DIR=$AOS_REPO_EXPERIMENT_DIR/$AOS_TEST_NAME
    if [ ! -d $AOS_REPO_EXPERIMENT_DIR ]; then
        echo "CONFIG ERROR: experiment directory $AOS_REPO_EXPERIMENT_DIR not found!"
        exit 1
    elif [ ! -d $AOS_REPO_TEST_DIR ]; then
        echo "CONFIG ERROR: test directory $AOS_REPO_TEST_DIR not found!"
        exit 1
    else
        # import client platform base config (if any)
        client_platform_cfg=$AOS_REPO_ROOT/platforms/client/$AOS_PLATFORM_CLIENT/platform.cfg
        import_config $client_platform_cfg
        
        # import server platform base config (if any)
        server_platform_cfg=$AOS_REPO_ROOT/platforms/server/$AOS_PLATFORM_SERVER/platform.cfg
        import_config $server_platform_cfg

        # import experiment base config (if any)
        exp_cfg=$AOS_REPO_EXPERIMENT_DIR/exp.cfg
        import_config $exp_cfg

        # import test base config (if any)
        tst_cfg=$AOS_REPO_TEST_DIR/test.cfg
        import_config $tst_cfg

        # import test platform configs (if any)
        tst_client_hw_cfg=$AOS_REPO_TEST_DIR/scripts/config/${AOS_PLATFORM_CLIENT}.platform.cfg
        import_config $tst_client_hw_cfg
        tst_server_hw_cfg=$AOS_REPO_TEST_DIR/scripts/config/${AOS_PLATFORM_SERVER}.platform.cfg
        import_config $tst_server_hw_cfg

        # import test software configs (if any)
        if [ -n "$AOS_CLIENT_SOFTWARE" -a -n "$AOS_CLIENT_SOFTWARE_VERSION" ]; then
            # import base software+version config (if any)
            tst_app_cfg=$AOS_REPO_ROOT/source/applications/${AOS_CLIENT_SOFTWARE}/${AOS_CLIENT_SOFTWARE_VERSION}/software.cfg
            import_config $tst_app_cfg
            tst_bench_cfg=$AOS_REPO_ROOT/source/benchmarks/${AOS_CLIENT_SOFTWARE}/${AOS_CLIENT_SOFTWARE_VERSION}/software.cfg
            import_config $tst_bench_cfg
            tst_util_cfg=$AOS_REPO_ROOT/source/utilities/${AOS_CLIENT_SOFTWARE}/${AOS_CLIENT_SOFTWARE_VERSION}/software.cfg
            import_config $tst_util_cfg
        fi

        if [ ${AOS_CONFIG_ERROR:-0} -ne 0 ]; then
            echo "CONFIG ERROR: Aborting test due to prior configuration error!"
            exit $AOS_CONFIG_ERROR
        else
            config_variables="$(compgen -v 'AOS_')"
            declare -x $config_variables
        fi
    fi
fi