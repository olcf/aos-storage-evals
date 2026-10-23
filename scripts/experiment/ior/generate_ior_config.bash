#!/bin/bash
#
# DESCRIPTION: generates an ior config file for the given input
#              configuration and current value of AOS_TARGET
#
# USAGE: source or execute from another bash script
#
# ARGS: input-config output-config
#
# ENVIRONMENT:
# - USES
#     AOS_IO_UNIQUE_DIR  - whether to use per-client directories
#     AOS_TARGET             - I/O target (device, directory, or file)
#     AOS_TARGET_CREATE      - whether to create the target
#


# NOTE: any variable named with the prefix 'ior_' defined below will
#       be treated as an official ior configuration variable that gets
#       added to the output config

if [ $# -ne 2 ]; then
    echo "USAGE ERROR: $0 <input-config-file> <output-config-file>"
    exit -1
fi

iorcfg=$1
if [ ! -f $iorcfg ]; then
    echo "ERROR: ior configuration file $iorcfg is not valid"
    exit 1
else
    echo >&2 "INFO: using ior configuration file $iorcfg"
fi
source $iorcfg

cfg_file=$2
if [ -f $cfg_file ]; then
    echo >&2 "INFO: ior config file $cfg_file exists and will be overwritten"
    /bin/rm -f $cfg_file
fi

opt_file=${cfg_file}.cliopt
if [ -f $opt_file ]; then
    echo >&2 "INFO: ior config command-line options file $opt_file exists and will be overwritten"
    /bin/rm -f $opt_file
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
if [ $create -eq 0 ]; then
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
else
    # assume target is a file
    target_file=$target
fi

echo >&2 "INFO: using target $target"

jobcfg_dir=$(dirname $cfg_file)

# the following is to handle ior api-specific config options with periods in
# their names that cannot be used in config files and must be passed via the
# command-line. transforms 'ior_<api>_<option>' to '--<api>.<option>'
the_api=${ior_api:-""}
api_config_settings=""
if [ -n "$the_api" ]; then
    lower_api=$( echo $the_api | tr '[:upper:]' '[:lower:]' )
    api_config_vars=($(compgen -v "ior_${lower_api}_"))
    for var in "${api_config_vars[@]}"; do
        var_name=$(echo $var | sed -e "s/^ior_${lower_api}_/--${lower_api}./")
        var_value=$(eval echo \"\${$var\}\")
        api_config_settings+="$var_name=$var_value "
        unset $var
    done
fi
[ -n "$api_config_settings" ] && echo -n "$api_config_settings" > $opt_file

if [ -n "$target_dir" ]; then
    if [ ${AOS_IO_UNIQUE_DIR:-0} -eq 0 ]; then
        ior_uniqueDir=1
    fi
fi

config_vars=($(compgen -v "ior_"))

if [[ -n "$AOS_SCRIPT_DEBUG" && $AOS_SCRIPT_DEBUG -eq 1 ]]; then
    echo >&2
    echo >&2 "CONFIG DEBUG: ior input config ($iorcfg)"
    echo >&2 "CONFIG DEBUG: ++++++++++++++++"
    for var in "${config_vars[@]}"; do
        echo >&2 "CONFIG DEBUG: $var =" $(eval echo \"\${$var\}\")
    done
    [ -n "$api_config_settings" ] && echo >&2 "CONFIG DEBUG: command-line options: $api_config_settings"
    echo >&2 "CONFIG DEBUG: ++++++++++++++++"
fi

# create config file(s)
touch $cfg_file
echo "IOR START" >> $cfg_file
for var in "${config_vars[@]}"; do
    var_name=$(echo $var | sed -e 's/^ior_//')
    var_value=$(eval echo \"\${$var\}\")
    echo "$var_name=$var_value" >> $cfg_file
done
echo "summaryAlways=1" >> $cfg_file
echo "RUN" >> $cfg_file
echo "IOR STOP" >> $cfg_file

echo >&2
echo >&2 "CONFIG: ior Config File ($cfg_file)"
echo >&2 "CONFIG: +++++++++++++++"
cat $cfg_file >&2
echo >&2 "CONFIG: +++++++++++++++"
echo >&2
exit 0