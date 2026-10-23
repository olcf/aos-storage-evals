#!/bin/bash
#
# DESCRIPTION: generates a file-stress-test command line for the given input configuration
#              and current value of AOS_TARGET
#
# USAGE: source from another bash script
#
# ARGS: fst-config
#
# ENVIRONMENT:
# - USES
#     AOS_IO_UNIQUE_DIR  - whether to use per-client directories
#     AOS_TARGET             - I/O target (device, directory, or file)
#     AOS_TARGET_CREATE      - whether to create the target
# - DEFINES
#     AOS_CLIENT_COMMAND         - full command to run for fst client process


# NOTE: any variable named with the prefix 'fst_' defined below will
#       be treated as an official fst configuration variable that gets
#       added to the job file

if [ $# -ne 1 ]; then
    echo "USAGE ERROR: source $0 <input-config-file>"
    exit -1
fi

fstcfg=$1
if [ ! -f $fstcfg ]; then
    echo "ERROR: fst configuration file $fstcfg is not valid"
    exit 1
else
    echo >&2 "INFO: using fst configuration file $fstcfg"
fi
source $fstcfg

# check target after sourcing the config file, which may define it
target_dir=""
target=${AOS_TARGET:-""}
if [ -z "$target" ]; then
    echo "ERROR: AOS_TARGET is not set!"
    exit 2
else
    target_dir=$target
fi

if [ -n "$fst_target" ]; then
    target_dir=$fst_target
    echo >&2 "INFO: updated target to $fst_target"
    export AOS_TARGET=$fst_target
    unset fst_target
fi

if [ -z "$target_dir" ]; then
    echo "ERROR: target directory is not set!"
    exit 2
fi
echo >&2 "INFO: using target directory $target_dir"

fst_exe_path=${AOS_FST_EXECUTABLE:-"file-stress-test"}
if [ -n "$fst_exe" ]; then
    fst_exe_path=$fst_exe
    export AOS_FST_EXECUTABLE=$fst_exe
    unset fst_exe
fi

create=${AOS_TARGET_CREATE:-0}
if [ $create -eq 1 ]; then
    if [ ! -d $target_dir ]; then
        # try to create the target directory
        /bin/mkdir -p $target_dir || { echo "ERROR: could not create target directory $target_dir"; exit 1; }
    fi
fi

fstjob="${AOS_EXPERIMENT_NAME}.${AOS_TEST_NAME}"

fst_directory=$target_dir

config_vars=($(compgen -v "fst_"))

echo >&2
echo >&2 "CONFIG: file-stress-test Configuration ($fstcfg)"
echo >&2 "CONFIG: ++++++++++++++++++++++++++++++"
for var in "${config_vars[@]}"; do
    echo >&2 "CONFIG: $var =" $(eval echo \"\${$var\}\")
done
echo >&2 "CONFIG: ++++++++++++++++++++++++++++++"
echo >&2

fst_command_options="-D $fst_directory"
[ "$fst_create" == "1" ]     && fst_command_options+=" -w"
[ "$fst_read" == "1" ]       && fst_command_options+=" -r"
[ "$fst_unique" == "1" ]     && fst_command_options+=" -u"
[ -n "$fst_filesize" ]       && fst_command_options+=" -S $fst_filesize"
[ -n "$fst_filecount" ]      && fst_command_options+=" -C $fst_filecount"
[ -n "$fst_bench_seconds" ]  && fst_command_options+=" -B $fst_bench_seconds"
[ -n "$fst_warmup_seconds" ] && fst_command_options+=" -W $fst_warmup_seconds"

fst_client_command="$fst_exe_path $fst_command_options"
export AOS_CLIENT_COMMAND=$fst_client_command
