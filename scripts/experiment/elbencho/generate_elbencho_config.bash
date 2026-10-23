#!/bin/bash
#
# DESCRIPTION: generates an elbencho config file for the given input
#              configuration and current value of AOS_TARGET
#
# USAGE: source or execute from another bash script
#
# ARGS: input-config output-config
#
# ENVIRONMENT:
# - USES
#     AOS_IO_UNIQUE_DIR  - whether to use per-client directories
#     AOS_TARGET         - I/O target (device, directory, or file)
#     AOS_TARGET_CREATE  - whether to create the target
#


# NOTE: any variable named with the prefix 'elbencho_' defined below will
#       be treated as an official elbencho configuration variable that gets
#       added to the output config

if [ $# -ne 2 ]; then
    echo "USAGE ERROR: $0 <input-config-file> <output-config-file>"
    exit -1
fi

ebcfg=$1
if [ ! -f $ebcfg ]; then
    echo "ERROR: elbencho configuration file $ebcfg is not valid"
    exit 1
else
    echo >&2 "INFO: using elbencho configuration file $ebcfg"
fi
source $ebcfg

cfg_file=$2
if [ -f $cfg_file ]; then
    echo >&2 "INFO: elbencho config file $cfg_file exists and will be overwritten"
    /bin/rm -f $cfg_file
fi

# check target after sourcing the config file, which may define it
target_dir=""
target_file=""
target=${AOS_TARGET:-""}
if [ -z "$target" ]; then
    echo "ERROR: AOS_TARGET is not set!"
    exit 2
elif [ -d $target ]; then
    echo >&2 "INFO: using target directory $target"
    target_dir=$target
else
    echo >&2 "INFO: using target file $target"
    target_file=$target
fi

if [ -n "$elbencho_exe" ]; then
    echo "AOS_ELBENCHO_EXECUTABLE=$elbencho_exe" >> ${cfg_file}.aosenv
    unset elbencho_exe
fi

if [ -n "$elbencho_scan_exe" ]; then
    echo "AOS_ELBENCHO_SCAN_PATH_EXECUTABLE=$elbencho_scan_exe" >> ${cfg_file}.aosenv
    export AOS_ELBENCHO_SCAN_PATH_EXECUTABLE=$elbencho_scan_exe
    unset elbencho_scan_exe
fi

if [ -n "$elbencho_target" ]; then
    if [ -d $elbencho_target ]; then
        target_dir=$elbencho_target
    else
        target_file=$elbencho_target
    fi
    echo >&2 "INFO: updated target to $elbencho_target"
    echo "AOS_TARGET=$elbencho_target" >> ${cfg_file}.aosenv
    unset elbencho_target
fi

job_name="${AOS_EXPERIMENT_NAME}.${AOS_TEST_NAME}"
if [ -n "$elbencho_label" ]; then
    job_name=$elbencho_label
fi

jobcfg_dir=$(dirname $cfg_file)

if [ -n "$target_dir" ]; then
    if [ "$elbencho_treefile" == "1" ]; then
        # config specifies use a treefile, so generate if it's not present
        AOS_ELBENCHO_TREEFILE=$jobcfg_dir/elbencho.treefile
        if [ ! -f $AOS_ELBENCHO_TREEFILE ]; then
            eb_scripts=$(dirname $0)
            source $eb_scripts/generate_treefile.bash $target_dir
        fi
        elbencho_treefile=$AOS_ELBENCHO_TREEFILE
    elif [ ${AOS_IO_UNIQUE_DIR:-0} -eq 0 ]; then
        elbencho_dirsharing=1
    fi
fi

config_vars=($(compgen -v "elbencho_"))

echo >&2
echo >&2 "CONFIG: elbencho input config ($ebcfg)"
echo >&2 "CONFIG: +++++++++++++++++++++"
for var in "${config_vars[@]}"; do
    echo >&2 "CONFIG: $var =" $(eval echo \"\${$var\}\")
done
echo >&2 "CONFIG: +++++++++++++++++++++"

# create config file
touch $cfg_file

for var in "${config_vars[@]}"; do
    var_name=$(echo $var | sed -e 's/^elbencho_//')
    var_value=$(eval echo \"\${$var\}\")
    echo "$var_name=$var_value" >> $cfg_file
done

echo >&2
echo >&2 "CONFIG: elbencho Config File ($cfg_file)"
echo >&2 "CONFIG: ++++++++++++++++++++"
cat $cfg_file >&2
echo >&2 "CONFIG: ++++++++++++++++++++"
echo >&2
exit 0