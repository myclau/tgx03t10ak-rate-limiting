#!/bin/bash
LANG=en_us_8859_1 
dbname="full-data.db"
file="full-data-access.log"
batch_size="10000"
function insert-db(){
    ___start=`date +%s%N`
    sqlite3 "$dbname" << END_SQL
$query
END_SQL
    ___end=`date +%s%N`
    ___runtime=$((__end-__start))
    echo "[DB write] It take $((___runtime/1000000)) millisecond"
}

function insert-line(){
    count=0
    query=""
    while read ip datetime method uri; do
        __start=`date +%s%N`

        #echo "$line"
        #ip=$(echo "$line"| cut -d ' ' -f 1)
        #datetime=$(echo "$line" | cut -d[ -f2 | cut -d] -f1 | sed 's/\//-/g' | sed 's/:/ /' )
        #request_method_uri=$(echo "$line"| cut -d '"' -f2 | cut -d '"' -f1 )
        #IFS=' ' read -r method uri http <<< "$request_method_uri"
        #echo "ip $ip,datetime $datetime,request_method_uri $request_method_uri,method $method,uri $uri"
        #extract_line=$(echo "$line" |  sed -n 's/^\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\).*\[\(.* +[0-9]\{4\}\)\].*\"\(.*\) \(.*\) HTTP.*/\1,\2,\3,\4/p')
        #IFS=',' read -r ip datetime method uri <<< ${extract_line}
        #datetime=$(echo $datetime | sed 's/:/ /' | sed 's/+/ +/g' )
        
        timestamp=$(date -d  "${datetime/:/ }" +"%s")
        query+="INSERT INTO accesslog (ip,datetime,timestamp,method,uri) VALUES (\"$ip\",\"${datetime/:/ }\",\"$timestamp\",\"$method\",\"$uri\");"
        ((count++))
        #echo "ip $ip,datetime $timestamp,method $method,uri $uri"

        if (( $count ==  $batch_size)); then
            echo "[DEBUG] loop: query"
            insert-db
            count=0
            query=""
            
        fi
        __end=`date +%s%N`
        __runtime=$((__end-__start))
        echo "[EXTRACT LINE]It take $((__runtime/1000000)) millisecond"
    done
    if (( $count >  0)); then
            echo "[DEBUG] last: query"
            insert-db

    fi
}

start=`date +%s`
if [ ! -f "$dbname" ]; then
    sqlite3 "$dbname" <<'END_SQL'
CREATE TABLE IF NOT EXISTS accesslog (id INTEGER PRIMARY KEY AUTOINCREMENT,ip TEXT,datetime TEXT,timestamp INTEGER,method TEXT,uri TEXT);
END_SQL
fi
echo "Reading logs..."

#cat "$file" | insert-line
#gsub("+"," +",$5);
#awk '{gsub(/\[/,"",$4);gsub(/\]/,"",$5);gsub("/","-",$4);gsub(/\"/,"",$6);print $1,$4$5,$6,$7}' "$file" | insert-line
awk '{gsub(/\[/,"",$4);gsub(/\]/,"",$5);gsub("/","-",$4);gsub(/\"/,"",$6);print $1,$4$5,$6,$7}' "$file" | insert-line


end=`date +%s`
runtime=$((end-start))
echo "All Process completed in $runtime second"