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
        ######## using grep ########

        #touch $tempfile_name
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
        #############################
        #echo "$current_timestamp"
        start_timestring=$(date -d @$((current_timestamp - $last_seconds)) +"%d/%b/%Y:%H:%M:%S")
        end_timestring=$(date -d @$current_timestamp +"%d/%b/%Y:%H:%M:%S")
        #cat "$file" | sed "s/\[//g" | awk -vstart="[$start_timestring" -vend="[$end_timestring" '{ if ($4>=start && $4<=end) print $0}' >> $tempfile_name
        awk -vstart="[$start_timestring" -vend="[$end_timestring" '{ if ($4>=start && $4<=end) print $0}' "$file" >> $tempfile_name


        # last_seconds_first_timestamp=$((current_timestamp - last_seconds))
        # touch "$tempfile_name"
        # echo "[DEBUG] current_timestamp: $current_timestamp ,first_line_timestamp: $first_line_timestamp, last_seconds_first_timestamp: $last_seconds_first_timestamp, last_line_timestamp: $last_line_timestamp  "
        # if (( $current_timestamp >=  $first_line_timestamp )) && (( $last_seconds_first_timestamp <=  $last_line_timestamp )) && (( $last_seconds_first_timestamp >=  $first_line_timestamp )); then

        #     temp_current_timestamp=$current_timestamp
        #     temp_current_timestring=$(date -d @$temp_current_timestamp +"%d/%b/%Y:%H:%M:%S")
        #     temp_start_timestamp=$last_seconds_first_timestamp
        #     temp_start_timestring=$(date -d @$temp_start_timestamp +"%d/%b/%Y:%H:%M:%S")
        #     #echo "temp_start: ${temp_start_timestring//\//\\/} temp_current: ${temp_current_timestring//\//\\/}"

        #     temp_start_timestring_exist=$(grep "$temp_start_timestring" "$file" | wc -l) 
        #     while (( $temp_start_timestring_exist == 0 ))
        #     do
        #         temp_start_timestamp=$((temp_start_timestamp + 1))
        #         temp_start_timestring=$(date -d @$((temp_start_timestamp)) +"%d/%b/%Y:%H:%M:%S")
        #         temp_start_timestring_exist=$(grep "$temp_start_timestring" "$file" | wc -l)
        #     done
        #     temp_current_timestring_exist=$(grep "$temp_current_timestring" "$file" | wc -l) 
        #     while (( $temp_current_timestring_exist == 0 ))
        #     do
        #         if (( $temp_current_timestamp > $last_line_timestamp )); then
        #             temp_current_timestring=$last_line_timestring
        #             break
        #         fi
        #         temp_current_timestamp=$((temp_current_timestamp - 1))
        #         temp_current_timestring=$(date -d @$((temp_start_timestamp)) +"%d/%b/%Y:%H:%M:%S")
        #         temp_current_timestring_exist=$(grep "$temp_current_timestring" "$file" | wc -l)
        #     done
        #     if [ "$temp_start_timestring" == "$temp_current_timestring" ]; then
        #         sed -n "/${temp_start_timestring//\//\\/}/ p" "$file" > "$tempfile_name"
        #     else
        #         sed -n "/${temp_start_timestring//\//\\/}/,/${temp_current_timestring//\//\\/}/ p" "$file" > "$tempfile_name"
        #     fi
        # else
        #     echo "[Warning] Log is not suitable for checking"
        # fi
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
#echo "$current_timestring"
current_timestamp=$(date -d  "$current_timestring" +"%s")
data_ip=()
data_bantime=()

first_line_timestring=$(head -n 1 "$file" | cut -d ' ' -f 4 )
first_line_timestring=$(echo "$first_line_timestring" | sed 's/\[//g' )
first_line_timestring_date=$(echo "$first_line_timestring" | sed 's/\//-/g' )
first_line_timestring_date=$(echo "$first_line_timestring_date" | sed 's/:/ /' )
if [ "$first_line_timestring_date" == "" ]; then
    first_line_timestamp=""
else
    first_line_timestamp=$(date -d  "$first_line_timestring_date" +"%s")
fi
last_line_timestring=$(tail -n 1 "$file" | cut -d ' ' -f 4 )
last_line_timestring=$(echo "$last_line_timestring" | sed 's/\[//g' )
last_line_timestring_date=$(echo "$last_line_timestring" | sed 's/\//-/g' )
last_line_timestring_date=$(echo "$last_line_timestring_date" | sed 's/:/ /' )
if [ "$last_line_timestring_date" == "" ]; then
    last_line_timestamp=""
else
    last_line_timestamp=$(date -d  "$last_line_timestring_date" +"%s")
fi
if [ "$first_line_timestamp" == "" ]; then
    echo "No Suitable Content found "
    exit 1
fi

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


