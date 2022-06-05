#!/bin/bash

LANG=en_us_8859_1 

start=`date +%s%N`
dbname=${1-"data.db"}
#tempfile_name="temp.log"
output_file="action_record.csv"
#### custom input ####
#using for debug assume current time is 01-Jan-2019 00:05:19
#current_timestring=${2-"01-Jan-2019 00:06:19"}
#using real current time
real_current_timestring=$(date +"%d-%b-%Y %H:%M:%S")
current_timestring=${2-"$real_current_timestring"}


#current_timestring="31-Dec-2018 23:56:56"
#dbname="full-data.db"
########################




function check-if-need-ban() {
    
    last_seconds=$1
    restrict_threshold=$2
    unban_time=$3
    restrict_endpoint=${4-"/*"}
    
    #temp_start=`date +%s%N`
    #echo "[Process Start] checking last $last_seconds second's log, if ip request $restrict_threshold time for endpoint [$restrict_endpoint] then block for $unban_time second"
    #echo "Check in db"

    if [ "$restrict_endpoint" == '/*' ]; then
        querysubstring=""
    else
        querysubstring="AND uri == \"$restrict_endpoint\""
    fi
    temp_result_file="results-$current_timestamp-$restrict_threshold.txt"
    query=$(cat << EOF
.mode columns
.output $temp_result_file
SELECT ip, count(*) AS req_count
FROM accesslog 
WHERE 
timestamp >= $((current_timestamp-last_seconds)) AND timestamp <= $current_timestamp  $querysubstring
GROUP BY ip 
HAVING count(*) >= $restrict_threshold ;

EOF
)
    #echo $query

    sqlite3 "$dbname"<< END_SQL
$query
END_SQL

    sed -i -e "/^ip.*req_count/d" -e "/^--.*--/d" "$temp_result_file"
    #sed -i "/^--.*--/d" "$temp_result_file"

    while read -r ip requestcount ; do
        #echo "$ip $requestcount"
        recorded="false"
        for ((i = 0; i < ${#data_ip[@]}; ++i)); do
            recordip=${data_ip[$i]}
            if [ "$recordip" == "$ip" ];then
                #echo "[NEED UPDATE UNBAN TIME]" 
                recordbantime=${data_bantime[$i]}
                if (( $recordbantime < $unban_time )); then
                    data_bantime[$i]=$unban_time
                fi
                recorded="true"
                break
            fi
        done
        if [ "$recorded" == "false" ];then
            data_ip+=("$ip")
            data_bantime+=("$unban_time")
            #echo "[write ip] data_ip count ${#data_ip[@]} ${#data_bantime[@]}"
            #echo "[write ip $ip $unban_time]" 
        fi
    done <"$temp_result_file"

    #echo "[completed]" 
    #temp_end=`date +%s%N`
    #temp_runtime=$((temp_end-temp_start))
    #echo "[Process completed in $((temp_runtime/1000000)) millisecond]"

}


current_timestamp=$(date -d  "$current_timestring" +"%s")
data_ip=()
data_bantime=()


#execute rule1
check-if-need-ban 600 20 7200 "/login"
#execute rule2
check-if-need-ban 600 100 3600
#execute rule3
check-if-need-ban 60 40 600

#clean up file 
rm -f ./results-$current_timestamp-*.txt

touch "$output_file"

#echo "data_ip count ${#data_ip[@]} ${#data_bantime[@]}"
#Base on the entries from above checking, output to CSV file
#echo "[Start output BAN and UNBAN result]"
for ((i = 0; i < ${#data_ip[@]}; ++i)); do
    recordip=${data_ip[$i]}
    blocktime=${data_bantime[$i]}
    unblocktime=$(( current_timestamp + blocktime))
    #unblocktimetimestring=$(date -d @$unblocktime +"%d-%b-%Y %H:%M:%S")
    exist_last_unban_entry=$(grep ",UNBAN,$recordip" "$output_file" | tail -1)
    #echo "$recordip $blocktime $exist_last_unban_timestamp"
    need_to_write_to_csv="true" 
    if [ "$exist_last_unban_entry" != "" ]; then
        exist_last_unban_timestamp=$(echo "$exist_last_unban_entry" | cut -d ',' -f 1)
        if (( $exist_last_unban_timestamp > $unblocktime )); then
            need_to_write_to_csv="false"
            #echo "[DEBUG] As ip: $recordip already target to ban and the orgin unban time is longer than current target unban time so skipped."
        else
            if (( $exist_last_unban_timestamp >  $current_timestamp ));then
                need_to_write_to_csv="false"
                #echo "[DEBUG] As ip: $recordip already target to ban and the current unban time is longer than orgin target unban time so update entry in csv."
                #remove old unban lines
                sed -i "/$exist_last_unban_entry/d" "$output_file"
                #add new unban lines
                echo "[Checker][DEBUG][UPDATE Entry][$current_timestring]$unblocktime,UNBAN,$recordip"
                echo "$unblocktime,UNBAN,$recordip" >> "$output_file"
            fi
        fi
    fi
    if [ "$need_to_write_to_csv" == "true" ]; then
        echo "[Checker][DEBUG][ADD Entry][$current_timestring] $current_timestamp[$current_timestring],BAN,$recordip"
        echo "$current_timestamp,BAN,$recordip" >> "$output_file"
        echo "[Checker][DEBUG][ADD Entry][$current_timestring] $unblocktime,UNBAN,$recordip"
        echo "$unblocktime,UNBAN,$recordip" >> "$output_file"
    fi
done
#echo "[Completed]"
end=`date +%s%N`
runtime=$((end-start))
echo "[Checker][$current_timestring] All Process completed in $((runtime/1000000)) millisecond"

