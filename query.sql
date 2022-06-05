SELECT ip, count(*) AS req_count
    FROM accesslog 
    WHERE 
    timestamp >= 1546271216 AND timestamp <= 1546271816  AND uri == "/login"
    GROUP BY ip 
    HAVING count(*) >= 40 ;

SELECT ip, count(*) AS req_count
    FROM accesslog 
    WHERE 
    timestamp >= 1546271216 AND timestamp <= 1546271816
    GROUP BY ip 
    HAVING count(*) >= 40 ;