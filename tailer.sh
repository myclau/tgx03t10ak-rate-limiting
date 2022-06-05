#!/bin/bash
LANG=en_us_8859_1
file="access.log"
#assume_current_timestring="31-Dec-2018 23:55:00"
batch_size="5"
dbname="data.db"
timestamp_diff=0

child_pid=0


touch $file
if [ ! -f "$dbname" ]; then
    sqlite3 "$dbname" <<'END_SQL'
CREATE TABLE IF NOT EXISTS accesslog (ip TEXT,datetime TEXT,timestamp INTEGER,method TEXT,uri TEXT,status INTEGER);
END_SQL
fi

count=0
query=""
#while read -r logLine ; do
while read -r ip b c d e method uri h status j k l ; do
   start=`date +%s%N`
   #echo "[LINE] $ip $b $c $d $e $method $uri $h $status $j $k $l"
   datetime="${d//'['/} ${e//']'/}"
   datetime=${datetime//\//-}
   timestamp=$(date -d  "${datetime/:/ }" +"%s")



   query+="INSERT INTO accesslog VALUES (\"$ip\",\"${datetime/:/ }\",\"$timestamp\",\"${method//'"'/}\",\"$uri\",\"$status\");"
   ((count++))
   
   if (( $count ==  $batch_size)); then
       #exec_current_timestamp=$(date +%s)
       #if [ "$assume_current_timestring" != "" ] && [ "$timestamp_diff" == "0" ]; then
       #    assume_current_timestamp=$(date -d  "$assume_current_timestring" +"%s")
       #    timestamp_diff=$((exec_current_timestamp-assume_current_timestamp))
       #fi
       #exec_current_timestring=$(date -d @$((exec_current_timestamp-timestamp_diff)) +"%d-%b-%Y %H:%M:%S")
       exec_current_timestring=$(date -d @$((timestamp)) +"%d-%b-%Y %H:%M:%S")
       if [ "$child_pid" != "0" ]; then
            wait $child_pid
       fi
       ./insert-db.sh "$dbname" "$query" "$exec_current_timestring" &
       child_pid=$!
       count=0
       query=""
       echo "[DB write] fired"
       
   fi
   #insert-db
   end=`date +%s%N`
   runtime=$((end-start))
   echo "Read Record in $((runtime/1000000)) millisecond"
done< <(exec tail -fn0 "$file")


