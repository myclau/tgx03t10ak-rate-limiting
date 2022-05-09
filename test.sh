#!/bin/bash

LANG=en_us_8859_1 
current_timestamp="1546271816"
last_seconds=600
file=empty.log
file=access.log
temp_start=`date +%s`
tempfile_name="temp-$current_timestamp-$last_seconds.log"


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

echo "$first_line_timestring"
echo "$first_line_timestring_date"
echo "$first_line_timestamp"
echo "$last_line_timestring"
echo "$last_line_timestring_date"
echo "$last_line_timestamp"

last_seconds_first_timestamp=$((current_timestamp - last_seconds))
touch "$tempfile_name"
if (( $current_timestamp >=  $first_line_timestamp )) && (( $last_seconds_first_timestamp <=  $last_line_timestamp )) && (( $last_seconds_first_timestamp >=  $first_line_timestamp )); then
    
    temp_current_timestamp=$current_timestamp
    temp_current_timestring=$(date -d @$temp_current_timestamp +"%d/%b/%Y:%H:%M:%S")
    temp_start_timestamp=$last_seconds_first_timestamp
    temp_start_timestring=$(date -d @$temp_start_timestamp +"%d/%b/%Y:%H:%M:%S")
    #echo "temp_start: ${temp_start_timestring//\//\\/} temp_current: ${temp_current_timestring//\//\\/}"
    
    temp_start_timestring_exist=$(grep "$temp_start_timestring" "$file" | wc -l) 
    while (( $temp_start_timestring_exist == 0 ))
    do
        temp_start_timestamp=$((temp_start_timestamp + 1))
        temp_start_timestring=$(date -d @$((temp_start_timestamp)) +"%d/%b/%Y:%H:%M:%S")
        temp_start_timestring_exist=$(grep "$temp_start_timestring" "$file" | wc -l)
    done
    temp_current_timestring_exist=$(grep "$temp_current_timestring" "$file" | wc -l) 
    while (( $temp_current_timestring_exist == 0 ))
    do
        if (( $temp_current_timestamp > $last_line_timestamp )); then
            temp_current_timestring=$last_line_timestring
            break
        fi
        temp_current_timestamp=$((temp_current_timestamp - 1))
        temp_current_timestring=$(date -d @$((temp_start_timestamp)) +"%d/%b/%Y:%H:%M:%S")
        temp_current_timestring_exist=$(grep "$temp_current_timestring" "$file" | wc -l)
    done
    if [ "$temp_start_timestring" == "$temp_current_timestring" ]; then
        sed -n "/${temp_start_timestring//\//\\/}/ p" "$file" > "$tempfile_name"
    else
        sed -n "/${temp_start_timestring//\//\\/}/,/${temp_current_timestring//\//\\/}/ p" "$file" > "$tempfile_name"
    fi

fi
#search_timestring=""
#

#for ((i = $last_seconds; i >= 0; i--)); do
#    temp_timestring=$(date -d @$((current_timestamp - i)) +"%d/%b/%Y:%H:%M:%S")
#    if [ "$search_timestring" == "" ]; then
#        search_timestring="$temp_timestring"
#    else
#        search_timestring="$search_timestring\|$temp_timestring"
#    fi
#done
#echo "$search_timestring"
temp_end=`date +%s`
temp_runtime=$((temp_end-temp_start))
echo "[completed in $temp_runtime seconds]" 