#!/bin/bash

LANG=en_us_8859_1 

function check-if-need-ban() {
    
    last_seconds=$1
    restrict_threshold=$2
    unban_time=$3
    restrict_endpoint=${4-"/*"}
    tempfile_name="temp-$current_timestamp-$last_seconds.log"
    temp_start=`date +%s`
    echo "[Process Start] checking last $last_seconds second's log, if ip request $restrict_threshold time for endpoint [$restrict_endpoint] then block for $unban_time second"
    echo "[Grepping log for last $last_seconds]" 
    
    # grep log for last x second , and skip if already greped before
    if [ ! -f "$tempfile_name" ]; then
        touch $tempfile_name
        ## it takes 15 sec to finish
        #search_timestring=""
        #for ((i = $last_seconds; i >= 0; i--)); do
    	#    temp_timestring=$(date -d @$((current_timestamp - i)) +"%d/%b/%Y:%H:%M:%S")
        #    if [ "$search_timestring" == "" ]; then
        #        search_timestring="$temp_timestring"
        #    else
        #        search_timestring="$search_timestring\|$temp_timestring"
        #    fi
        #done
        #grep "$search_timestring" "$file" >> $tempfile_name

        ## it takes less then 1 sec to finish
        temp_current_timestring=$(date -d @$((current_timestamp)) +"%d/%b/%Y:%H:%M:%S")
        temp_start_timestring=$(date -d @$((current_timestamp - last_seconds)) +"%d/%b/%Y:%H:%M:%S")
        sed -n "/${temp_start_timestring//\//\\/}/,/${temp_current_timestring//\//\\/}/ p" "$file" > $tempfile_name
    
    fi
    temp_end=`date +%s`
    temp_runtime=$((temp_end-temp_start))
    echo "[completed in $temp_runtime seconds]" 
    #ip exist in target log
    ip_list=($(cat "$tempfile_name" | cut -d ' ' -f 1 | sort -n | uniq -c | awk '{print $(NF)}'))

    echo "[Processing condition]"
    for ((i = 0; i < ${#ip_list[@]}; i++));do
        ip=${ip_list[$i]}
        if [ "$ip" != "" ]; then
            if [ "$restrict_endpoint" == "/*" ]; then
                search_string="$ip"
            else
                search_string="$ip.*$restrict_endpoint"
                #echo "$search_string"
            fi
            if (( ${#ip} >= 7 )); then
                #grep "$search_string" $tempfile_name
                ip_count=$(grep -o "$search_string" $tempfile_name | wc -l)
                #echo "$ip - $ip_count"
                if (( ip_count >= restrict_threshold ));then
                    #echo "$current_timestamp,BAN,$ip"
                    recorded="false"
                    for ((j = 0; j < ${#data_ip[@]}; ++j)); do
                        recordip=${data_ip[$j]}
                        if [ "$recordip" == "$ip" ];then
                            recordbantime=${data_bantime[$j]}
                            if (( recordbantime < unban_time )); then
                                data_bantime[$j]=$unban_time
                            fi
                            recorded="true"
                            break
                        fi
                    done
                    if [ "$recorded" == "false" ];then
                        data_ip+=($ip)
                        data_bantime+=($unban_time)
                    fi

                fi

            fi
        fi
    done
    echo "[completed]" 
    temp_end=`date +%s`
    temp_runtime=$((temp_end-temp_start))
    echo "[Process completed in $temp_runtime]"

}

start=`date +%s`
file=${1-"access.log"}
#tempfile_name="temp.log"
output_file="action_record.csv"
#### custom input ####
#using for debug assume current time is 01-Jan-2019 00:05:19
#current_timestring=${2-"01-Jan-2019 00:06:19"}
#using real current time
real_current_timestring=$(date +"%d-%b-%Y %H:%M:%S")
current_timestring=${2-"$real_current_timestring"}
########################

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
rm -f ./temp-$current_timestamp*.log

touch "$output_file"
#Base on the entries from above checking, output to CSV file
echo "[Start output BAN and UNBAN result]"
for ((i = 0; i < ${#data_ip[@]}; ++i)); do
    recordip=${data_ip[$i]}
    blocktime=${data_bantime[$i]}
    unblocktime=$(( current_timestamp + blocktime))
    unblocktimetimestring=$(date -d @$unblocktime +"%d-%b-%Y %H:%M:%S")
    exist_last_unban_entry=$(grep ",UNBAN,$recordip" "$output_file" | tail -1)
    exist_last_unban_timestamp=$(echo "$exist_last_unban_entry" | cut -d ',' -f 1)
    #echo "$exist_last_unban_timestamp"
    need_to_write_to_csv="true" 
    if [ "$exist_last_unban_timestamp" != "" ]; then
        if (( $exist_last_unban_timestamp > $unblocktime )); then
            need_to_write_to_csv="false"
            echo "[DEBUG] As ip: $recordip already target to ban and the orgin unban time is longer than current target unban time so skipped."
        else
            if (( $exist_last_unban_timestamp >  $current_timestamp ));then
                need_to_write_to_csv="false"
                echo "[DEBUG] As ip: $recordip already target to ban and the current unban time is longer than orgin target unban time so update entry in csv."
                #remove old unban lines
                sed -i "/$exist_last_unban_entry/d" "$output_file"
                #add new unban lines
                echo "[DEBUG][UPDATE Entry] $unblocktime[$unblocktimetimestring],UNBAN,$recordip"
                echo "$unblocktime,UNBAN,$recordip" >> "$output_file"
            fi
        fi
    fi
    if [ "$need_to_write_to_csv" == "true" ]; then
        echo "[DEBUG][ADD Entry] $current_timestamp[$current_timestring],BAN,$recordip"
        echo "$current_timestamp,BAN,$recordip" >> "$output_file"
        echo "[DEBUG][ADD Entry] $unblocktime[$unblocktimetimestring],UNBAN,$recordip"
        echo "$unblocktime,UNBAN,$recordip" >> "$output_file"
    fi
done
echo "[Completed]"
end=`date +%s`
runtime=$((end-start))
echo "All Process completed in $runtime second"


