-- checking a specific session if is a proc (helps identifying what step of the proc is running)

DECLARE @SPID INT = ; 

SELECT 
    r.session_id,
    DB_NAME(t.dbid) AS 'database',
    OBJECT_NAME(t.objectid, t.dbid) AS 'proc',
    SUBSTRING(
        t.[text], 
        (r.statement_start_offset / 2) + 1, 
        (
            (CASE r.statement_end_offset 
                WHEN -1 THEN DATALENGTH(t.[text]) 
                ELSE r.statement_end_offset 
            END - r.statement_start_offset) / 2
        ) + 1
    ) AS runningcommand,
    r.status,
    r.command,
    r.wait_type,
    (r.wait_time / 1000.0) AS wait_time_sec,
    (r.total_elapsed_time / 1000.0) AS elapsed_time_sec,
    r.logical_reads
FROM 
    sys.dm_exec_requests r
CROSS APPLY 
    sys.dm_exec_sql_text(r.sql_handle) t
WHERE 
    r.session_id = @SPID;