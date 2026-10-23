# USAGE: source this from a bash script
#
# ARGS: target-directory

scanner=`which ${AOS_ELBENCHO_SCAN_PATH_EXECUTABLE:-elbencho-scan-path}`
treefile=${AOS_ELBENCHO_TREEFILE:=$PWD/elbencho.treefile}
tf_dir=$(dirname $treefile)

target_dir=$1
if [ ! -d "$target_dir" ]; then
    echo "ERROR: $target_dir is not a valid directory target!"
elif [ ! -x "$scanner" ]; then
    echo "ERROR: $scanner is not a valid executable!"
else
    full_scan_cmd="$scanner -o $treefile $target_dir"
    echo >&2 "INFO: Running elbencho-scan-path to generate treefile: $full_scan_cmd"
    $full_scan_cmd > $tf_dir/elbencho-scan-path.log 2>&1
    if [ $? -eq 0 ]; then
        treefile_stats=$(/bin/ls -l $treefile)
        echo >&2 "INFO: generated treefile: $treefile_stats"
    fi
fi
