#!/bin/bash
LANG=en_us_8859_1 
start_timestring="31-Dec-2018 23:55:00"
end_timestring="01-Jan-2019 08:47:38"
start_timestamp=$(date -d  "$start_timestring" +"%s")
end_timesstamp=$(date -d  "$end_timestring" +"%s")


current_timestamp=$start_timestamp

while (( current_timestamp <= end_timesstamp ))
do
    current_timestring=$(date -d @$current_timestamp +"%d-%b-%Y %H:%M:%S")
    echo "./main.sh \"access.log\" \"$current_timestring\"" 
    __start=`date +%s`
    ./main.sh "access.log"  "$current_timestring"
    __end=`date +%s`
    __runtime=$((__end-__start))
    cronjob_period=$__runtime
    current_timestamp=$((current_timestamp + cronjob_period))
done