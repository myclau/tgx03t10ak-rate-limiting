#!/bin/bash
LANG=en_us_8859_1 
source_file="full-data-access.log"
out_file="access.log"
sleep_control="60000000"
TZ=Asia/Hong_Kong
sim_log_start_timestring="31-Dec-2018 23:55:00"
sim_log_end_timestring="01-Jan-2019 08:47:38"
sim_log_start_timestamp=$(date -d  "$sim_log_start_timestring" +"%s")
sim_log_end_timesstamp=$(date -d  "$sim_log_end_timestring" +"%s")
sim_log_interval=$((sim_log_end_timesstamp - sim_log_start_timestamp))

touch "$out_file"
current_timestamp=$sim_log_start_timestamp

search_timestring=""
for ((i = 0; i <= sim_log_interval; i++)); do
    _start=`date +%s%N`
    temp_timestring=$(date -d @$((current_timestamp + i)) +"%d/%b/%Y:%H:%M:%S %z")
    #echo $temp_timestring
    grep "$temp_timestring" "$source_file" >> $out_file
    _end=`date +%s%N`
    #_interval=$((_end - _start))
    _sleeptime=$((1000000000 - _end + _start - sleep_control))
    _sleepString="$_sleeptime/1000000000"
    _sleeptime_sec=$(awk "BEGIN{print $_sleepString}")
    if [[ $_sleeptime_sec != "-"* ]]; then
        sleep $_sleeptime_sec
    fi    
    __end=`date +%s%N`
    __runtime=$((__end-_start))
    echo "[Popper] ($temp_timestring) It take $((__runtime/1000000)) millisecond"
done
