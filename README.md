# tgx03t10ak-rate-limiting
 

# Logic flow
1. keep reading access logfile from apache output (defualt is ./access.log) 
2. everytime when script execute will set a static timestamp (current time) as reference
3. base on the static current time from (2) check below condition:   
    3.1. any ip request `/login` `20` times in past `10 minutes` (current time -> last 600s) `ban` these ip for `2 hour`  
    3.2. any ip request `/*` `100` times in past `10 minutes` (current time -> last 600s) `ban` these ip for `1 hour`  
    3.3. any ip request `/*` `40` times in past `1 minutes` (current time -> last 60s) `ban` these ip for `10 minutes`  
4. Will Run All condition from (3), if ip hit more than one condition should get banned with the longest ban time
5. output ip ban record and target unban record at the same time into csv files (action_record.csv)
6. if ip should already record need to be ban, but this ip keep hitting the condition, the unban time will be extend until no hit is found
7. csv record will accumulated
8. This script should need to keep running.

# Technical design for the script
1. define a static variable for current time
2. need a time as reference otherwise difficult to tell what is the time period for (last 1/10 minutes)
3. as appache log are outputing n lines of log for second (not mini second)
4. so we can grep log using grep command and using current time - 1 second until -60 seconds or -600 seconds
5. in (4) this approach is much much faster than reading the whole log with for loop every lines
6. store the only log we need in temp-$current_time-$last_second.log so that if need to check past x mintes again no need to grep these log again
7. using the temp store log, grep ip and endpoint according to condition and save the ip , counts and ban time
8. if ip already exist in current process as it hit previos rules, check if the ban time is longer or shorter, if longer then update it as the longer one
9. after completed 3 conditions,clean up the temp log files as process completed
10. base on the new hit record found in current process  
    10.1. Check if that ip already exist in CSV or not  
    10.2. if no, add ban entry (current time) and target unban entry (current time + ban time) to CSV file  
    10.3. if yes, check below condition  
          10.3.1. if the current target unban time is longer than the record in CSV, update that record in CSV (remove old record and new record)  
          10.3.2. if the current target unban time is less than the record in CSV , just skip it.  
          10.3.3. if the current ban time is large then the unban record in CSV, which mean the ip should already unban and hit the rules again, so need to create new ban and target unban history to CSV like (10.2.)  


# Prerequisite

1. any linux env with bash 
2. install git


# How to Use (please completed reading Expected result below before try to run it)

1. git clone
2. cd to workdirectory
3. run below command will run a quick test where assume the sample log file is ./access.log and  the checking time is "01-Jan-2019 00:05:19"
```bash
./main.sh "access.log" "01-Jan-2019 00:05:19"
```
4. run below command to run the checking with current time and default path ./access.log
```bash
./main.sh
```
5. run below command to run the test to generate the sample answer
```bash
./output_sample_answer.sh
```
6. run below command to run the full test according to the requirement
```bash
./overall_test.sh
```

# Assumption 

1. The log format will not be change and also in this way
```<ip> - - [<date time>] <any log message>``` 




# Limition
1. only can read appache access log
2. access.log should keep being update in real time
3. if access log is too big it will be time consuming
4. will be explain more on section Expected result


# Expected result (output)


## Unit test

### simple run
Assume the current time as `01-Jan-2019 00:05:19`, then execute it

run command
```bash
./main.sh "access.log" "01-Jan-2019 00:05:19"
```


Console log:
```bash
$ ./main.sh "access.log" "01-Jan-2019 00:05:19"
[Process Start] checking last 600 second's log, if ip request 20 time for endpoint [/login] then block for 7200 second
[Grepping log for last 600]
current_timestamp: 1546272319 ,first_line_timestamp: 1546271700, last_seconds_first_timestamp: 1546271719, last_line_timestamp: 1546303658
[completed in 0 seconds]
[Processing condition]
[completed]
[Process completed in 5]
[Process Start] checking last 600 second's log, if ip request 100 time for endpoint [/*] then block for 3600 second
[Grepping log for last 600]
[completed in 0 seconds]
[Processing condition]
[completed]
[Process completed in 4]
[Process Start] checking last 60 second's log, if ip request 40 time for endpoint [/*] then block for 600 second
[Grepping log for last 60]
current_timestamp: 1546272319 ,first_line_timestamp: 1546271700, last_seconds_first_timestamp: 1546272259, last_line_timestamp: 1546303658  
[completed in 0 seconds]
[Processing condition]
[completed]
[Process completed in 3]
[Start output BAN and UNBAN result]
[DEBUG][ADD Entry] 1546272319[01-Jan-2019 00:05:19],BAN,58.236.203.13
[DEBUG][ADD Entry] 1546279519[01-Jan-2019 02:05:19],UNBAN,58.236.203.13
[Completed]
All Process completed in 14 second
```

action_record.csv:
```csv
1546272319,BAN,58.236.203.13
1546279519,UNBAN,58.236.203.13

```

### Check if unban record can be update

Then assume the script run again in next minutes:

Set the time to `01-Jan-2019 00:06:19` and execute again. As 58.236.203.13 will hit the condition again but it should not be unban yet and the unban time should extend.

run command
```bash
./main.sh "access.log" "01-Jan-2019 00:06:19"
```

Console log:
```bash
$ ./main.sh "access.log" "01-Jan-2019 00:06:19"
[Process Start] checking last 600 second's log, if ip request 20 time for endpoint [/login] then block for 7200 second
[Grepping log for last 600]
[DEBUG] current_timestamp: 1546272379 ,first_line_timestamp: 1546271700, last_seconds_first_timestamp: 1546271779, last_line_timestamp: 1546303658  
[completed in 1 seconds]
[Processing condition]
[completed]
[Process completed in 5]
[Process Start] checking last 600 second's log, if ip request 100 time for endpoint [/*] then block for 3600 second
[Grepping log for last 600]
[completed in 0 seconds]
[Processing condition]
[completed]
[Process completed in 5]
[Process Start] checking last 60 second's log, if ip request 40 time for endpoint [/*] then block for 600 second
[Grepping log for last 60]
[DEBUG] current_timestamp: 1546272379 ,first_line_timestamp: 1546271700, last_seconds_first_timestamp: 1546272319, last_line_timestamp: 1546303658  
[completed in 0 seconds]
[Processing condition]
[completed]
[Process completed in 4]
[Start output BAN and UNBAN result]
[DEBUG] As ip: 58.236.203.13 already target to ban and the current unban time is longer than orgin target unban time so update entry in csv.
[DEBUG][UPDATE Entry] 1546279579[01-Jan-2019 02:06:19],UNBAN,58.236.203.13
[Completed]
All Process completed in 14 second
```
action_record.csv:
```csv
1546272319,BAN,58.236.203.13
1546279579,UNBAN,58.236.203.13

```

### Check if new ban record can be add if last unban record is expire

Set the time to `01-Jan-2019 02:07:19` and execute again. Here we set the time is two hour later (simulate nothing need to ban in this two hour) as 58.236.203.13 will hit the condition again and current time is greater than the last 58.236.203.13's unban time , so which means we need to ban it again.

run command
```bash
./main.sh "access.log" "01-Jan-2019 02:07:19"
```

Console log:
```bash
$  ./main.sh "access.log" "01-Jan-2019 02:07:19"
[Process Start] checking last 600 second's log, if ip request 20 time for endpoint [/login] then block for 7200 second
[Grepping log for last 600]
[DEBUG] current_timestamp: 1546279639 ,first_line_timestamp: 1546271700, last_seconds_first_timestamp: 1546279039, last_line_timestamp: 1546303658  
[completed in 0 seconds]
[Processing condition]
[completed]
[Process completed in 5]
[Process Start] checking last 600 second's log, if ip request 100 time for endpoint [/*] then block for 3600 second
[Grepping log for last 600]
[completed in 0 seconds]
[Processing condition]
[completed]
[Process completed in 5]
[Process Start] checking last 60 second's log, if ip request 40 time for endpoint [/*] then block for 600 second
[Grepping log for last 60]
[DEBUG] current_timestamp: 1546279639 ,first_line_timestamp: 1546271700, last_seconds_first_timestamp: 1546279579, last_line_timestamp: 1546303658  
[completed in 0 seconds]
[Processing condition]
[completed]
[Process completed in 3]
[Start output BAN and UNBAN result]
[DEBUG][ADD Entry] 1546279639[01-Jan-2019 02:07:19],BAN,58.236.203.13
[DEBUG][ADD Entry] 1546286839[01-Jan-2019 04:07:19],UNBAN,58.236.203.13
[Completed]
All Process completed in 13 second
```
action_record.csv:
```csv
1546272319,BAN,58.236.203.13
1546279579,UNBAN,58.236.203.13
1546279639,BAN,58.236.203.13
1546286839,UNBAN,58.236.203.13

```
### Check what if log file is empty

run command
```bash
./main.sh "empty.log" "01-Jan-2019 02:07:19"
```

result
```bash
$  ./main.sh "empty.log" "01-Jan-2019 02:07:19"
No Suitable Content found
```

### Check if the time is set too early from the log file


run command
```bash
./main.sh "access.log" "01-Jan-2016 02:07:19"
```

result
```bash
$  ./main.sh "access.log" "01-Jan-2016 02:07:19"
[Process Start] checking last 600 second's log, if ip request 20 time for endpoint [/login] then block for 7200 second
[Grepping log for last 600]
[DEBUG] current_timestamp: 1451585239 ,first_line_timestamp: 1546271700, last_seconds_first_timestamp: 1451584639, last_line_timestamp: 1546303658  
[Warning] Log is not suitable for checking
[completed in 0 seconds]
[Processing condition]
[completed]
[Process completed in 0]
[Process Start] checking last 600 second's log, if ip request 100 time for endpoint [/*] then block for 3600 second
[Grepping log for last 600]
[completed in 0 seconds]
[Processing condition]
[completed]
[Process completed in 0]
[Process Start] checking last 60 second's log, if ip request 40 time for endpoint [/*] then block for 600 second
[Grepping log for last 60]
[DEBUG] current_timestamp: 1451585239 ,first_line_timestamp: 1546271700, last_seconds_first_timestamp: 1451585179, last_line_timestamp: 1546303658  
[Warning] Log is not suitable for checking
[completed in 0 seconds]
[Processing condition]
[completed]
[Process completed in 0]
[Start output BAN and UNBAN result]
[Completed]
All Process completed in 1 second
```

Script will warning you that Log is not suitable for checking

### Check if the time is set too far away from the log file

run command
```bash
./main.sh "access.log" "01-Jan-2020 02:07:19"
```

result
```bash
$  ./main.sh "access.log" "01-Jan-2020 02:07:19"
[Process Start] checking last 600 second's log, if ip request 20 time for endpoint [/login] then block for 7200 second
[Grepping log for last 600]
[DEBUG] current_timestamp: 1577815639 ,first_line_timestamp: 1546271700, last_seconds_first_timestamp: 1577815039, last_line_timestamp: 1546303658  
[Warning] Log is not suitable for checking
[completed in 0 seconds]
[Processing condition]
[completed]
[Process completed in 0]
[Process Start] checking last 600 second's log, if ip request 100 time for endpoint [/*] then block for 3600 second
[Grepping log for last 600]
[completed in 0 seconds]
[Processing condition]
[completed]
[Process completed in 0]
[Process Start] checking last 60 second's log, if ip request 40 time for endpoint [/*] then block for 600 second
[Grepping log for last 60]
[DEBUG] current_timestamp: 1577815639 ,first_line_timestamp: 1546271700, last_seconds_first_timestamp: 1577815579, last_line_timestamp: 1546303658  
[Warning] Log is not suitable for checking
[completed in 0 seconds]
[Processing condition]
[completed]
[Process completed in 1]
[Start output BAN and UNBAN result]
[Completed]
All Process completed in 1 second
```
### Check if the time is set to just later then the log file last line about 9 mins

run command
```bash
./main.sh "access.log" "01-Jan-2020 02:07:19"
```

result
```bash
$  ./main.sh "access.log" "01-Jan-2019 08:56:38"
[Process Start] checking last 600 second's log, if ip request 20 time for endpoint [/login] then block for 7200 second
[Grepping log for last 600]
[DEBUG] current_timestamp: 1546304198 ,first_line_timestamp: 1546271700, last_seconds_first_timestamp: 1546303598, last_line_timestamp: 1546303658  
[completed in 0 seconds]
[Processing condition]
[completed]
[Process completed in 4]
[Process Start] checking last 600 second's log, if ip request 100 time for endpoint [/*] then block for 3600 second
[Grepping log for last 600]
[completed in 0 seconds]
[Processing condition]
[completed]
[Process completed in 4]
[Process Start] checking last 60 second's log, if ip request 40 time for endpoint [/*] then block for 600 second
[Grepping log for last 60]
[DEBUG] current_timestamp: 1546304198 ,first_line_timestamp: 1546271700, last_seconds_first_timestamp: 1546304138, last_line_timestamp: 1546303658  
[Warning] Log is not suitable for checking
[completed in 0 seconds]
[Processing condition]
[completed]
[Process completed in 0]
[Start output BAN and UNBAN result]
[Completed]
All Process completed in 8 second
```

YOu can see for checking last 10 mins rules it run as usually, but for checking last 1 min it will skip as data is not enough

### Check if the time is set to just later then the log file last line about 38 sec

run command
```bash
./main.sh "access.log" "01-Jan-2019 08:47:00"
```

result
```bash
$  ./main.sh "access.log" "01-Jan-2019 08:47:00"
[Process Start] checking last 600 second's log, if ip request 20 time for endpoint [/login] then block for 7200 second
[Grepping log for last 600]
[DEBUG] current_timestamp: 1546303620 ,first_line_timestamp: 1546271700, last_seconds_first_timestamp: 1546303020, last_line_timestamp: 1546303658  
[completed in 0 seconds]
[Processing condition]
[completed]
[Process completed in 5]
[Process Start] checking last 600 second's log, if ip request 100 time for endpoint [/*] then block for 3600 second
[Grepping log for last 600]
[completed in 0 seconds]
[Processing condition]
[completed]
[Process completed in 4]
[Process Start] checking last 60 second's log, if ip request 40 time for endpoint [/*] then block for 600 second
[Grepping log for last 60]
[DEBUG] current_timestamp: 1546303620 ,first_line_timestamp: 1546271700, last_seconds_first_timestamp: 1546303560, last_line_timestamp: 1546303658  
[completed in 1 seconds]
[Processing condition]
[completed]
[Process completed in 4]
[Start output BAN and UNBAN result]
[DEBUG][ADD Entry] 1546303620[01-Jan-2019 08:47:00],BAN,58.236.203.13
[DEBUG][ADD Entry] 1546310820[01-Jan-2019 10:47:00],UNBAN,58.236.203.13
[Completed]
All Process completed in 14 second
```

## OverAll Test

This is requirement (expected result and this is the provided answer):
```
1546271816,BAN,58.236.203.13 
1546277422,BAN,221.17.254.20 
1546281160,UNBAN,221.17.254.20 
1546285801,BAN,210.133.208.189 
1546293587,UNBAN,210.133.208.189 
1546297454,BAN,221.17.254.20 
1546301070,UNBAN,221.17.254.20 
1546310858,UNBAN,58.236.203.13 
```
Detail can read the requirement.md

From the requirement use first 2 ban to check if I can determine the running cycle

1546277422 - 1546271816  = 5,606 sec
5606 / 60 = 93.433333 minutes

so seems do not have running cycle pattern (let said the script is run every 1 mins) and it should be looping and running.

Firstly I try to reproduce the extact same result, base on the provided answer and do reverse engineering, and also test if my script logic is correct

output_sample_answer.sh:
```bash
#!/bin/bash
__start=`date +%s`
./main.sh "access.log" "31-Dec-2018 23:56:56"
./main.sh "access.log" "01-Jan-2019 00:06:55"
./main.sh "access.log" "01-Jan-2019 01:06:54"
./main.sh "access.log" "01-Jan-2019 01:30:22"
./main.sh "access.log" "01-Jan-2019 01:32:40"
./main.sh "access.log" "01-Jan-2019 02:30:21"
./main.sh "access.log" "01-Jan-2019 03:30:20"
./main.sh "access.log" "01-Jan-2019 03:50:01"
./main.sh "access.log" "01-Jan-2019 03:59:47"
./main.sh "access.log" "01-Jan-2019 04:50:00"
./main.sh "access.log" "01-Jan-2019 05:49:59"
./main.sh "access.log" "01-Jan-2019 06:49:58"
./main.sh "access.log" "01-Jan-2019 07:04:14"
./main.sh "access.log" "01-Jan-2019 07:04:30"
./main.sh "access.log" "01-Jan-2019 08:04:29"
./main.sh "access.log" "01-Jan-2019 08:47:38"
__end=`date +%s`
__runtime=$((__end-__start))
echo "It take $__runtime seconds"
```

run script output_sample_answer.sh:
```bash
./output_sample_answer.sh
```

action_record.csv:
```csv
1546271816,BAN,58.236.203.13
1546277422,BAN,221.17.254.20
1546281160,UNBAN,221.17.254.20
1546285801,BAN,210.133.208.189
1546293587,UNBAN,210.133.208.189
1546297454,BAN,221.17.254.20
1546301070,UNBAN,221.17.254.20
1546310858,UNBAN,58.236.203.13

```

From above testing I know that the script should start from `31-Dec-2018 23:55:00` to `01-Jan-2019:08:47:38` (which are the starting time and the end time of the sample log)

I dont think this test (output_sample_answer.sh) is what we want, we should simulated with the real situation.

so we have another test:
overall_test.sh
```bash
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
#make sure it run once more when the time is greater than target end time
./main.sh "access.log"  "$current_timestamp"
```

The current approach of `overall_test.sh`, start from `31-Dec-2018 23:55:00`, let say the first time need 30 second to complete, new execute time will be `31-Dec-2018 23:55:00` + 30 second = `31-Dec-2018 23:55:30`, until reach to the current time large than `01-Jan-2019 08:47:38` and Total will takes arround 9 hours to run completed

so the overall test will be `very very very very very` time consuming.

As the ban time is related to the script start time and each script start time is rely on last finish time (currently the processing time is ~between 28 sec to 33 sec~ around 15 sec), so the result is slighty different from the requirement


result:
action_record.csv:
```csv
1546271822,BAN,58.236.203.13
1546277424,BAN,221.17.254.20
1546281135,UNBAN,221.17.254.20
1546285806,BAN,210.133.208.189
1546293581,UNBAN,210.133.208.189
1546297459,BAN,221.17.254.20
1546301059,UNBAN,221.17.254.20
1546310858,UNBAN,58.236.203.13
```
sample answer vs my answer for 9 hours testing:
```
[BAN]   1546271816 - 1546271822 = -6 sec 
[BAN]   1546277422 - 1546277424 = -2 sec
[UNBAN] 1546281160 - 1546281135 = 25 sec
[BAN]   1546285801 - 1546285806 = -5 sec
[UNBAN] 1546293587 - 1546293581 = 6 sec
[BAN]   1546297454 - 1546297459 = -5 sec
[UNBAN] 1546301070 - 1546301059 = 11 sec 
[UNBAN] 1546310858 - 1546310858 = 0 sec
```
The different is about -9 to 24 sec, while `BAN` is more accurate the different is only -9 to 1 sec.

To reduce the different, only solution is keep each cycle finsih asap, if I can complete it in every sec, it should be very accurate, but seems not possible for my current solution.

I have already reduce the time from more than 60 sec -> 47-50 sec -> 28-31 sec -> 13-15 sec, I will be glad if I can find some way to make it quicker.

This is reference as the last bottle-neck is on grepping method
~From the console, I checked the time spend:~
~1. For rule 1 : any ip request `/login` `20` times in past `10 minutes` (current time -> last 600s) `ban` these ip for `2 hour`  ~
~15 sec for grepping log for last 10 mins in access.log, 5 sec for processing condition~
~2. For rule 2: any ip request `/*` `100` times in past `10 minutes` (current time -> last 600s) `ban` these ip for `1 hour`  ~
~As will reuse temp log from (1) so grep log is 0 sec , and 5 sec for processing condition~
~3.  For rule 3: any ip request `/*` `40` times in past `1 minutes` (current time -> last 60s) `ban` these ip for `10 minutes`  ~
~2 sec for grepping log , 3 sec for processing condition ~

~So the bottle neck seems is on grepping log for last 10 mins , it need to take 15 sec~

Although the running speed almost increase 50% but need to make sure grep lines between using sed the start and end pattern is exist in the file.
So need more complex line for do checking before calling sed.

 

