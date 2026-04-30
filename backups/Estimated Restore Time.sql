	SELECT 
    r.session_id,
    r.command,
    r.percent_complete,
    r.start_time,
    RIGHT('0' + CAST(DATEDIFF(HOUR, r.start_time, GETDATE()) AS VARCHAR), 2) + ':' +
    RIGHT('0' + CAST(DATEDIFF(MINUTE, r.start_time, GETDATE()) % 60 AS VARCHAR), 2) + ':' +
    RIGHT('0' + CAST(DATEDIFF(SECOND, r.start_time, GETDATE()) % 60 AS VARCHAR), 2) 
        AS running_time,
    RIGHT('0' + CAST((r.estimated_completion_time / 3600000) AS VARCHAR), 2) + ':' +
    RIGHT('0' + CAST((r.estimated_completion_time / 60000) % 60 AS VARCHAR), 2) + ':' +
    RIGHT('0' + CAST((r.estimated_completion_time / 1000) % 60 AS VARCHAR), 2) 
        AS time_left, 
    DATEADD(MILLISECOND, r.estimated_completion_time, GETDATE()) AS estimated_conclusion,
    CASE 
        WHEN DATEDIFF(MINUTE, r.start_time, GETDATE()) > 0 
        THEN CAST(r.percent_complete / DATEDIFF(MINUTE, r.start_time, GETDATE()) AS DECIMAL(10,4))
        ELSE 0 
    END AS percent_per_minute,
r.wait_type,
    t.text AS sql_command
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.command = 'RESTORE DATABASE'; -- filtering restore sessions

