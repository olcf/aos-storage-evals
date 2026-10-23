#!/bin/bash
#
# DESCRIPTION: For use within a bash script to process a single fio terse v3 line.
# The script generates bash variable assignments to stdout, so its output should
# be used with eval, as shown below.
#
# USAGE: execute from another bash script and eval its output
#
# ARGS: fio-terse-v3-line (as single quoted arg)
#
#   script|  fio_line=... # get semicolon separated fio terse v3 line
#   script|  eval $(/path/to/fio_terse_to_bash.bash "$fio_line")
#   script|  echo "fio version is $fio_version"
#   script|  echo "fio jobname is $jobname"
#   script|  echo "read performance is $read_bandwidth_kb KiB/sec ($read_iops IOPS)"
#   script|  echo "write performance is $write_bandwidth_kb KiB/sec ($write_iops IOPS)"

# v3 terse columns - this is taken directly from fio documentation
# (see https://fio.readthedocs.io/en/latest/fio_doc.html#terse-output)
# NOTE: this only accounts for a single set of disk utilization columns
num_names=130
terse_names="terse_version_3;fio_version;jobname;groupid;error;read_kb;read_bandwidth_kb;read_iops;read_runtime_ms;read_slat_min_us;read_slat_max_us;read_slat_mean_us;read_slat_dev_us;read_clat_min_us;read_clat_max_us;read_clat_mean_us;read_clat_dev_us;read_clat_pct01;read_clat_pct02;read_clat_pct03;read_clat_pct04;read_clat_pct05;read_clat_pct06;read_clat_pct07;read_clat_pct08;read_clat_pct09;read_clat_pct10;read_clat_pct11;read_clat_pct12;read_clat_pct13;read_clat_pct14;read_clat_pct15;read_clat_pct16;read_clat_pct17;read_clat_pct18;read_clat_pct19;read_clat_pct20;read_tlat_min_us;read_lat_max_us;read_lat_mean_us;read_lat_dev_us;read_bw_min_kb;read_bw_max_kb;read_bw_agg_pct;read_bw_mean_kb;read_bw_dev_kb;write_kb;write_bandwidth_kb;write_iops;write_runtime_ms;write_slat_min_us;write_slat_max_us;write_slat_mean_us;write_slat_dev_us;write_clat_min_us;write_clat_max_us;write_clat_mean_us;write_clat_dev_us;write_clat_pct01;write_clat_pct02;write_clat_pct03;write_clat_pct04;write_clat_pct05;write_clat_pct06;write_clat_pct07;write_clat_pct08;write_clat_pct09;write_clat_pct10;write_clat_pct11;write_clat_pct12;write_clat_pct13;write_clat_pct14;write_clat_pct15;write_clat_pct16;write_clat_pct17;write_clat_pct18;write_clat_pct19;write_clat_pct20;write_tlat_min_us;write_lat_max_us;write_lat_mean_us;write_lat_dev_us;write_bw_min_kb;write_bw_max_kb;write_bw_agg_pct;write_bw_mean_kb;write_bw_dev_kb;cpu_user;cpu_sys;cpu_csw;cpu_mjf;cpu_minf;iodepth_1;iodepth_2;iodepth_4;iodepth_8;iodepth_16;iodepth_32;iodepth_64;lat_2us;lat_4us;lat_10us;lat_20us;lat_50us;lat_100us;lat_250us;lat_500us;lat_750us;lat_1000us;lat_2ms;lat_4ms;lat_10ms;lat_20ms;lat_50ms;lat_100ms;lat_250ms;lat_500ms;lat_750ms;lat_1000ms;lat_2000ms;lat_over_2000ms;disk_name;disk_read_iops;disk_write_iops;disk_read_merges;disk_write_merges;disk_read_ticks;write_ticks;disk_queue_time;disk_util"
terse_cols=$(echo $terse_names | sed -e 's/;/ /g')

# for client-server, the disk util columns are omitted
cs_num_names=121
cs_terse_names="terse_version_3;fio_version;jobname;groupid;error;read_kb;read_bandwidth_kb;read_iops;read_runtime_ms;read_slat_min_us;read_slat_max_us;read_slat_mean_us;read_slat_dev_us;read_clat_min_us;read_clat_max_us;read_clat_mean_us;read_clat_dev_us;read_clat_pct01;read_clat_pct02;read_clat_pct03;read_clat_pct04;read_clat_pct05;read_clat_pct06;read_clat_pct07;read_clat_pct08;read_clat_pct09;read_clat_pct10;read_clat_pct11;read_clat_pct12;read_clat_pct13;read_clat_pct14;read_clat_pct15;read_clat_pct16;read_clat_pct17;read_clat_pct18;read_clat_pct19;read_clat_pct20;read_tlat_min_us;read_lat_max_us;read_lat_mean_us;read_lat_dev_us;read_bw_min_kb;read_bw_max_kb;read_bw_agg_pct;read_bw_mean_kb;read_bw_dev_kb;write_kb;write_bandwidth_kb;write_iops;write_runtime_ms;write_slat_min_us;write_slat_max_us;write_slat_mean_us;write_slat_dev_us;write_clat_min_us;write_clat_max_us;write_clat_mean_us;write_clat_dev_us;write_clat_pct01;write_clat_pct02;write_clat_pct03;write_clat_pct04;write_clat_pct05;write_clat_pct06;write_clat_pct07;write_clat_pct08;write_clat_pct09;write_clat_pct10;write_clat_pct11;write_clat_pct12;write_clat_pct13;write_clat_pct14;write_clat_pct15;write_clat_pct16;write_clat_pct17;write_clat_pct18;write_clat_pct19;write_clat_pct20;write_tlat_min_us;write_lat_max_us;write_lat_mean_us;write_lat_dev_us;write_bw_min_kb;write_bw_max_kb;write_bw_agg_pct;write_bw_mean_kb;write_bw_dev_kb;cpu_user;cpu_sys;cpu_csw;cpu_mjf;cpu_minf;iodepth_1;iodepth_2;iodepth_4;iodepth_8;iodepth_16;iodepth_32;iodepth_64;lat_2us;lat_4us;lat_10us;lat_20us;lat_50us;lat_100us;lat_250us;lat_500us;lat_750us;lat_1000us;lat_2ms;lat_4ms;lat_10ms;lat_20ms;lat_50ms;lat_100ms;lat_250ms;lat_500ms;lat_750ms;lat_1000ms;lat_2000ms;lat_over_2000ms"
cs_terse_cols=$(echo $cs_terse_names | sed -e 's/;/ /g')

if [ $# -ne 1 ]; then
    echo "USAGE ERROR: $0 <fio-tersev3-line>"
    exit 1
fi

terse_line=$1

if [[ ! $terse_line =~ ';' ]]; then
    echo "ERROR: provided input line has no semicolons!"
    exit 1
fi

terse_vals=$(echo $terse_line | sed -e 's/ /_/g; s/;/ /g')
[[ -n "$AOS_SCRIPT_DEBUG" && $AOS_SCRIPT_DEBUG -eq 1 ]] && echo >&2 "DEBUG: column values : $terse_vals"
num_values=$(echo $terse_vals | wc -w | awk '{print $1}')
[[ -n "$AOS_SCRIPT_DEBUG" && $AOS_SCRIPT_DEBUG -eq 1 ]] && echo >&2 "DEBUG: num values : $num_values"


if [ $num_values -eq $cs_num_names ]; then
    column_names=( $cs_terse_cols )
else
    column_names=( $terse_cols )
fi
column_values=( $terse_vals )

for ndx in $(seq 0 $(($num_values - 1))); do
    [[ -n "$AOS_SCRIPT_DEBUG" && $AOS_SCRIPT_DEBUG -eq 1 ]] && echo >&2 "DEBUG: ${column_names[$ndx]} = ${column_values[$ndx]}"
    echo "${column_names[$ndx]}=${column_values[$ndx]}"
done
