
/* What queries (> 100mb) are using TEMPDB */

;WITH espaco_utilizado AS (
    SELECT 
		session_id,
		request_id,
		SUM(internal_objects_alloc_page_count) AS alloc_pages,
		SUM(internal_objects_dealloc_page_count) AS dealloc_pages
    FROM sys.dm_db_task_space_usage WITH (NOLOCK)
    WHERE 
		session_id <> @@SPID
    GROUP BY 
		session_id, 
		request_id
)
SELECT 
	TSU.session_id,
	SESS.login_name,
    SESS.host_name,
    TSU.alloc_pages * 1.0 / 128 AS [TempDB Occupation],
    EST.text,
       -- Extract statement from sql text
          NULLIF(
               SUBSTRING(
                 EST.text, 
                 ERQ.statement_start_offset / 2, 
                 CASE WHEN ERQ.statement_end_offset < ERQ.statement_start_offset 
                  THEN 0 
                 ELSE( ERQ.statement_end_offset - ERQ.statement_start_offset ) / 2 END
               ), '') AS [statement text],
       EQP.query_plan
FROM espaco_utilizado AS TSU
INNER JOIN sys.dm_exec_requests ERQ WITH (NOLOCK) ON TSU.session_id = ERQ.session_id AND TSU.request_id = ERQ.request_id
INNER JOIN sys.dm_exec_sessions SESS WITH (NOLOCK) ON TSU.session_id = SESS.session_id
OUTER APPLY sys.dm_exec_sql_text(ERQ.sql_handle) AS EST
OUTER APPLY sys.dm_exec_query_plan(ERQ.plan_handle) AS EQP
WHERE 
	(EST.text IS NOT NULL OR EQP.query_plan IS NOT NULL)
	AND SESS.login_name NOT IN ('SMATEUS\usrsql01','datadog','sa','NT AUTHORITY\SYSTEM') -- change as you like
	AND (TSU.alloc_pages * 1.0 / 128) > 10 -- bigger than 100mb
ORDER BY 4 DESC;


-- Checking the current TEMPDB files usage
USE tempdb
GO
SELECT 
     a.name AS LogicalName
    ,a.filename AS PhysicalName
    ,CASE a.groupid 
        WHEN 0 THEN 'Log'
        ELSE 'Data' 
     END AS FileType
    ,'SizeinMB'         = (a.size / 128)
    ,fileproperty(a.name, 'spaceused') / 128 AS UsedinMB
    ,(a.size / 128) - fileproperty(a.name, 'SpaceUsed') / 128 AS FreeInMB
    ,CAST(
        ((a.size / 128.0) - fileproperty(a.name, 'SpaceUsed') / 128.0) 
        / (a.size / 128.0) * 100 
     AS NUMERIC(15)) AS [Free%]
    ,CASE 
        WHEN a.groupid <> 0 THEN
            ((a.size / 128.0) - fileproperty(a.name, 'SpaceUsed') / 128.0) 
            / SUM((a.size / 128.0) - (fileproperty(a.name, 'SpaceUsed') / 128.0)) 
              OVER (PARTITION BY fg.data_space_id)
        ELSE NULL  -- log não participa de filegroup
     END AS [PropFree%]
    ,ISNULL(fg.name, 'LOG') AS FilegroupName
FROM sysfiles a
LEFT JOIN sys.filegroups fg ON a.groupid = fg.data_space_id
 
-- Using whoisactive to check the most tempdb intensive queries

EXEC sp_WhoIsActive @find_block_leaders = 1,  @sort_order = '[tempdb_current] DESC'
 
-- Another way to check the most intensive tempdb queries
;with tab(session_id, host_name, login_name, totalalocadomb, text)
as(
SELECT a.session_id,
b.host_name,
b.login_name,
( user_objects_alloc_page_count + internal_objects_alloc_page_count ) * 1.0 / 128 AS totalalocadomb,
d.TEXT
FROM sys.dm_db_session_space_usage a
JOIN sys.dm_exec_sessions b ON a.session_id = b.session_id
JOIN sys.dm_exec_connections c ON c.session_id = b.session_id
CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) AS d
WHERE a.session_id > 50
AND ( user_objects_alloc_page_count + internal_objects_alloc_page_count ) * 1.0 / 128 > 1024 -- Ocupam mais de 10 MB
)
select top 20 * from tab order by 4 desc;

-- Understanding if there's any tempdb page latch

Select session_id,
wait_type,
wait_duration_ms,
blocking_session_id,
resource_description,
      ResourceType = Case
When Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) As Int) - 1 % 8088 = 0 Then 'Is PFS Page'
            When Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) As Int) - 2 % 511232 = 0 Then 'Is GAM Page'
            When Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) As Int) - 3 % 511232 = 0 Then 'Is SGAM Page'
            Else 'Is Not PFS, GAM, or SGAM page'
            End
From sys.dm_os_waiting_tasks
Where wait_type Like 'PAGE%LATCH_%'
And resource_description Like '2:%'


