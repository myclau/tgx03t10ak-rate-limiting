#!/bin/bash
__start=`date +%s`
./main.sh "test1.log" "31-Dec-2018 23:56:56"
./main.sh "test1.log" "01-Jan-2019 00:06:55"
./main.sh "test1.log" "01-Jan-2019 01:06:54"
./main.sh "test1.log" "01-Jan-2019 01:30:22"
./main.sh "test1.log" "01-Jan-2019 01:32:40"
./main.sh "test1.log" "01-Jan-2019 02:30:21"
./main.sh "test1.log" "01-Jan-2019 03:30:20"
./main.sh "test1.log" "01-Jan-2019 03:50:01"
./main.sh "test1.log" "01-Jan-2019 03:59:47"
./main.sh "test1.log" "01-Jan-2019 04:50:00"
./main.sh "test1.log" "01-Jan-2019 05:49:59"
./main.sh "test1.log" "01-Jan-2019 06:49:58"
./main.sh "test1.log" "01-Jan-2019 07:04:14"
./main.sh "test1.log" "01-Jan-2019 07:04:30"
./main.sh "test1.log" "01-Jan-2019 08:04:29"
./main.sh "test1.log" "01-Jan-2019 08:47:38"
__end=`date +%s`
__runtime=$((__end-__start))
echo "It take $__runtime seconds"