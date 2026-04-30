-- Shows the amount to be sent and applied
SELECT
    CAST(SYSUTCDATETIME() AS VARCHAR(19)) AS created_at
    , CAST(CONNECTIONPROPERTY('local_net_address') AS varchar) AS server_ip
    , ag.name AS [availability_group]
    , d.name AS [database_name]
    , ar.replica_server_name AS [replica_instance]
    , truncation_lsn = '..' + RIGHT(drs.truncation_lsn, 9)
--    , drs.log_send_queue_size AS send_queue_size
    , CASE
        WHEN drs.log_send_queue_size >= 1024 * 1024 * 1024 THEN 
            CAST(drs.log_send_queue_size / (1024 * 1024 * 1024) AS VARCHAR(20)) + ' GB'
        WHEN drs.log_send_queue_size >= 1024 * 1024 THEN 
            CAST(drs.log_send_queue_size / (1024 * 1024) AS VARCHAR(20)) + ' MB'
        WHEN drs.log_send_queue_size >= 1024 THEN 
            CAST(drs.log_send_queue_size / 1024 AS VARCHAR(20)) + ' KB'
        ELSE 
            CAST(drs.log_send_queue_size AS VARCHAR(20)) + ' B'
    END AS [send_queue_size]
    , drs.log_send_queue_size / isnull(nullif(drs.log_send_rate, 0), 1) / 60 as est_send_min
    , drs.log_send_queue_size / isnull(nullif(drs.log_send_rate, 0), 1) / 60 / 60 as est_send_hours
--    , drs.redo_queue_size
    , CASE
        WHEN drs.redo_queue_size >= 1024 * 1024 * 1024 THEN 
            CAST(drs.redo_queue_size / (1024 * 1024 * 1024) AS VARCHAR(20)) + ' GB'
        WHEN drs.redo_queue_size >= 1024 * 1024 THEN 
            CAST(drs.redo_queue_size / (1024 * 1024) AS VARCHAR(20)) + ' MB'
        WHEN drs.redo_queue_size >= 1024 THEN 
            CAST(drs.redo_queue_size / 1024 AS VARCHAR(20)) + ' KB'
        ELSE 
            CAST(drs.redo_queue_size AS VARCHAR(20)) + ' B'
    END AS [redo_queue_size]
    , drs.redo_queue_size / isnull(nullif(drs.redo_rate, 0), 1) / 60 as est_apply_min
    , drs.redo_queue_size / isnull(nullif(drs.redo_rate, 0), 1) / 60 /60 as est_apply_hours
FROM sys.availability_groups ag
INNER JOIN sys.availability_replicas ar ON ar.group_id = ag.group_id
INNER JOIN sys.dm_hadr_database_replica_states drs ON drs.replica_id = ar.replica_id
INNER JOIN sys.databases d ON d.database_id = drs.database_id
WHERE
    drs.is_local = 0
    AND (
--        drs.redo_queue_size / isnull(nullif(drs.redo_rate, 0), 1) / 60 >= 30
--      OR drs.log_send_queue_size / isnull(nullif(drs.log_send_rate, 0), 1) / 60 >= 30
        drs.redo_queue_size / (1024 * 1024) >= 1
        OR drs.log_send_queue_size / (1024 * 1024) >= 1
        OR drs.log_send_queue_size IS NULL
    )
ORDER BY
    ag.name ASC
    , d.name ASC
    , drs.truncation_lsn ASC
    , ar.replica_server_name ASC