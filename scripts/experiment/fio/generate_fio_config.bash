#!/bin/bash
#
# DESCRIPTION: generates a fio job file for the given input configuration
#              and current value of AOS_TARGET
#
# USAGE: execute from another bash script
#
# ARGS: fio-config fio-job
#
# ENVIRONMENT:
# - USES
#     AOS_IO_UNIQUE_DIR  - whether to use per-client directories
#     AOS_TARGET             - I/O target (device, directory, or file)
#     AOS_TARGET_CREATE      - whether to create the target
#


# NOTE: any variable named with the prefix 'fio_' defined below will
#       be treated as an official fio configuration variable that gets
#       added to the job file

if [ $# -ne 2 ]; then
    echo "USAGE ERROR: $0 <input-config-file> <output-job-file>"
    exit -1
fi

fiocfg=$1
if [ ! -f $fiocfg ]; then
    echo "ERROR: fio configuration file $fiocfg is not valid"
    exit 1
else
    echo >&2 "INFO: using fio configuration file $fiocfg"
fi
source $fiocfg

job_file=$2
if [ -f $job_file ]; then
    echo >&2 "INFO: fio job file $job_file exists and will be overwritten"
    /bin/rm -f $job_file
fi

# check target after sourcing the config file, which may define it
target_dir=""
target_dev=""
target_file=""
target=${AOS_TARGET:-""}
if [ -z "$target" ]; then
    echo "ERROR: AOS_TARGET is not set!"
    exit 2
fi
create=${AOS_TARGET_CREATE:-0}
if [ $create -eq 0 ]; then # make sure target already exists
    if [ ! -e $target ]; then
        echo "ERROR: target $target does not exist and target creation is disabled"
        exit 3
    elif [ -b $target ]; then
        target_dev=$target
    elif [ -d $target ]; then
        target_dir=$target
    elif [ -f $target ]; then
        target_file=$target
    else
        echo "ERROR: type of target $target not supported - should be file|dir|dev"
        exit 4
    fi
else # target(s) will be created
    if [ -n "$fio_directory" ]; then
        target_dir=$fio_directory
        unset fio_directory
    else
        # assume target is a file
        target_file=$target
    fi
fi

echo >&2 "INFO: using target $target"

fiojob="${AOS_EXPERIMENT_NAME}.${AOS_TEST_NAME}"
if [ -n "$fio_name" ]; then
    fiojob=$fio_name
    unset fio_name
fi

if [ -n "$target_dir" ]; then
    if [ -d $target_dir ]; then # it's an existing directory in local namespace
        fio_global_directory=$target_dir
        if [ ${AOS_IO_UNIQUE_DIR:-0} -eq 1 ]; then
            # separate directory per $jobnum ensures unique dir per client process
            fio_global_filename_format='/$clientuid_$jobnum/${AOS_TEST_NAME}_$filenum'
        else
            fio_global_filename_format='${AOS_TEST_NAME}_$clientuid_$jobnum_$filenum'
        fi
    else # most likely a remote namespace (e.g., DAOS)
        # can't use directory=' config, because fio tries to verify the target is a dir.
        # using 'filename_format=' config is supposed to auto-create any leading directories
        fio_global_filename_format=$target_dir
        if [ ${AOS_IO_UNIQUE_DIR:-0} -eq 1 ]; then
            # separate directory per $jobnum ensures unique dir per client process
            fio_global_filename_format+='/$clientuid_$jobnum/${AOS_TEST_NAME}_$filenum'
        else
            fio_global_filename_format+='_${AOS_TEST_NAME}_$clientuid_$jobnum_$filenum'
        fi
    fi
elif [ -n "$target_dev" ]; then
    fio_global_filename=$target_dev
else
    fio_global_filename=$target_file
fi

if [ -n "$fio_numjobs" ]; then
    # we are only interested in aggregate metrics
    fio_global_group_reporting=1
fi

config_vars=($(compgen -v "fio_"))

if [[ -n "$AOS_SCRIPT_DEBUG" && $AOS_SCRIPT_DEBUG -eq 1 ]]; then
    echo >&2
    echo >&2 "CONFIG DEBUG: fio Configuration ($fiocfg)"
    echo >&2 "CONFIG DEBUG: +++++++++++++++++"
    for var in "${config_vars[@]}"; do
        echo >&2 "CONFIG DEBUG: $var =" $(eval echo \"\${$var\}\")
    done
    echo >&2 "CONFIG DEBUG: +++++++++++++++++"
    echo >&2
fi

# create job file
touch $job_file

function add_fio_variable {
    local job=$1
    local var=$2
    local sed_expr='s/^fio_'${job}'_//;s/^fio_//'
    local var_name=$(echo $var | sed -e "$sed_expr")
    local var_value=$(eval echo \"\${$var\}\")
    #echo >&2 "DEBUG: var = $var_name, val = $var_value"
    #echo >&2 "DEBUG: file is $job_file "
    if [ -z "$var_value" ]; then
        echo "$var_name" >> $job_file
    else
        echo "$var_name=$var_value" >> $job_file
    fi
}

if [ -n "$fio_job_names" ]; then
    # need to process config settings in groups identified by prefix "fio_<jobname>_"
    for jobname in $fio_job_names; do
        echo "[$jobname]" >> $job_file
        job_config_vars=($(compgen -v "fio_${jobname}_"))
        for var in "${job_config_vars[@]}"; do
            add_fio_variable $jobname $var $job_file
        done
        echo >> $job_file
    done
else # single job
    echo "[$fiojob]" >> $job_file
    for var in "${config_vars[@]}"; do
        add_fio_variable "global" $var $job_file
    done
    echo >> $job_file
fi

echo >&2
echo >&2 "CONFIG: fio Job File ($job_file)"
echo >&2 "CONFIG: ++++++++++++"
cat $job_file >&2
echo >&2 "CONFIG: ++++++++++++"
echo >&2
exit 0
