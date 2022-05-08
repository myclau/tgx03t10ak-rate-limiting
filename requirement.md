# Requirements
 								
Write a program that will process a web server access log file and perform IP-based rate-limiting. The program outputs instructions for the load balancer to ban offending IP addresses.
		 					
Implement rate limiting using the following rules:

1. More than 40 requests from one IP address, in the past 1 minute ,IP address banned for the next 10 minutes 
2. More than 100 requests from one IP address, in the past 10 minutes,IP address banned for the next 1 hour			
3. More than 20 requests to ​/login​ from one IP address, in the past 10 minutes ,IP address banned for the next 2 hours 
	
 													
The program reads web server logs in the Apache “Combined Log Format”​ . You can assume one IP address represents exactly one client. 

Example input format:
```
222.219.188.0 - - [15/May/2019:17:12:55 +0800] "HEAD /settings HTTP/1.1" 200 5054 "" "" 
202.158.64.0 - - [15/May/2019:17:20:44 +0800] "GET /fresh HTTP/1.1" 200 4990 "" "" 
222.88.170.255 - - [15/May/2019:17:23:23 +0800] "GET /search HTTP/1.1" 200 4914 "" "" 
88.52.98.255 - - [15/May/2019:17:26:52 +0800] "POST /login HTTP/1.1" 401 4916 "" "" 
88.52.98.255 - - [15/May/2019:17:26:52 +0800] "POST /login HTTP/1.1" 401 4916 "" "" 
88.52.98.255 - - [15/May/2019:17:26:53 +0800] "POST /login HTTP/1.1" 401 4916 "" "" 
88.52.98.255 - - [15/May/2019:17:26:54 +0800] "POST /login HTTP/1.1" 401 4916 "" "" 
62.41.64.0 - - [15/May/2019:17:27:01 +0800] "GET /fresh HTTP/1.1" 200 4990 "" "" 
88.52.98.255 - - [15/May/2019:17:27:01 +0800] "POST /login HTTP/1.1" 401 4916 "" ""
```	



The program produces output in CSV format with 3 columns: (1)timestamp of action, (2)the action (​BAN​ or ​UNBAN​), and (3)IP address in question.

Processing which must produce exactly the following output: 

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