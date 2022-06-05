#!/bin/bash
__start=`date +%s`
./checker.sh "full-data.db" "31-Dec-2018 23:56:56"
./checker.sh "full-data.db" "01-Jan-2019 00:06:55"
./checker.sh "full-data.db" "01-Jan-2019 01:06:54"
./checker.sh "full-data.db" "01-Jan-2019 01:30:22"
./checker.sh "full-data.db" "01-Jan-2019 01:32:40"
./checker.sh "full-data.db" "01-Jan-2019 02:30:21"
./checker.sh "full-data.db" "01-Jan-2019 03:30:20"
./checker.sh "full-data.db" "01-Jan-2019 03:50:01"
./checker.sh "full-data.db" "01-Jan-2019 03:59:47"
./checker.sh "full-data.db" "01-Jan-2019 04:50:00"
./checker.sh "full-data.db" "01-Jan-2019 05:49:59"
./checker.sh "full-data.db" "01-Jan-2019 06:49:58"
./checker.sh "full-data.db" "01-Jan-2019 07:04:14"
./checker.sh "full-data.db" "01-Jan-2019 07:04:30"
./checker.sh "full-data.db" "01-Jan-2019 08:04:29"
./checker.sh "full-data.db" "01-Jan-2019 08:47:38"
__end=`date +%s`
__runtime=$((__end-__start))
echo "It take $__runtime seconds"