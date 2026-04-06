
/* Checking backups directories */
SELECT 
    bs.database_name,
    bs.backup_start_date,
    bs.backup_finish_date,
    bs.expiration_date,
    bmf.physical_device_name
FROM 
    msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE 
    bs.type = 'D' -- 'D' indica backup completo (full)
    AND bs.database_name = 'producao' -- escolha o database
ORDER BY 
    bs.backup_finish_date DESC;

/* Checking databases + backup */
SELECT
    DB_NAME() AS database_name,
    CONCAT(CAST(SUM(
        CAST( (size * 8.0/1024/1024/1024) AS DECIMAL(15,2) )
    ) AS VARCHAR(20)),' TB') AS database_size
FROM sys.database_files;

SELECT TOP 1
msdb.dbo.backupset.database_name,
msdb.dbo.backupset.backup_finish_date,
(CAST(msdb.dbo.backupset.backup_size AS NUMERIC(35,2))/1048576.0 / 1024 / 1024) AS backup_size_TB
FROM msdb.dbo.backupmediafamily
INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id
INNER JOIN sys.databases db on db.name = msdb.dbo.backupset.database_name
WHERE msdb.dbo.backupset.type = 'D'
and backup_finish_date > dateadd(week,-1,getdate())
and db.database_id = db_id()
ORDER BY
backup_finish_date desc

/* Checking backup erros in agent jobs */

SELECT count(distinct b.name) as Backupfail
FROM msdb.dbo.sysjobhistory A  JOIN msdb.dbo.sysjobs B ON B.job_id = A.job_id 
WHERE B.[name] like '% %'  and B.[name] not like '%log%' and a.step_name = 'backup' and a.sql_severity <> 0
having convert(date,convert(varchar,max(a.run_date)),113) >= convert(date,getdate()-1)

-- Consulta detalhada
SELECT *
FROM msdb.dbo.sysjobhistory A  JOIN msdb.dbo.sysjobs B ON B.job_id = A.job_id 
WHERE B.[name] like '% %'  and B.[name] not like '%log%' and a.step_name = 'backup' and a.sql_severity <> 0