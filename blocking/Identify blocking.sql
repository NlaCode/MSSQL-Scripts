USE tempdb;
SET NOCOUNT ON;

IF OBJECT_ID('master.dbo.sp_WhoIsActive') IS NULL
BEGIN
    RAISERROR('sp_WhoIsActive not found in Master Database.', 16, 1); 
    RETURN;
END

BEGIN TRY

    IF OBJECT_ID('tempdb..##WIA') IS NOT NULL DROP TABLE ##WIA;

    DECLARE @s VARCHAR(MAX);

    EXEC master.dbo.sp_WhoIsActive         
         @sort_order           = '[start_time] ASC'
        ,@get_outer_command    = 1
        ,@find_block_leaders   = 1
        ,@get_transaction_info = 1
        ,@get_task_info        = 2
        ,@return_schema        = 1
        ,@schema               = @s OUTPUT;

    SET @s = REPLACE(@s, '<table_name>', '##WIA');
    EXEC(@s);

    EXEC master.dbo.sp_WhoIsActive         
         @sort_order           = '[start_time] ASC'
        ,@get_outer_command    = 1
        ,@find_block_leaders   = 1
        ,@get_transaction_info = 1
        ,@get_task_info        = 2
        ,@destination_table    = '##WIA';

    IF NOT EXISTS (SELECT 1 FROM ##WIA WHERE blocking_session_id IS NOT NULL AND blocking_session_id <> session_id)
    BEGIN
        RAISERROR('No blocks found.', 0, 1) WITH NOWAIT;
        DROP TABLE ##WIA; 
        RETURN;
    END

END TRY
BEGIN CATCH
    IF OBJECT_ID('tempdb..##WIA') IS NOT NULL DROP TABLE ##WIA;
    
    DECLARE @Err VARCHAR(500) = 'ERRO: ' + ERROR_MESSAGE() 
                              + ' | Linha: ' + CAST(ERROR_LINE() AS VARCHAR);
    RAISERROR(@Err, 16, 1); 
    RETURN;
END CATCH;

;WITH T_BLOCKERS AS (
    -- Anchor Member: Head blockers
    SELECT 
         r.*
        ,0 AS RecursionLevel
        ,CAST(RIGHT('0000' + CAST(r.session_id AS VARCHAR(10)), 4) AS VARCHAR(1000)) AS [LEVEL]
    FROM ##WIA r
    WHERE ISNULL(r.blocking_session_id, r.session_id) = r.session_id
      AND EXISTS (
          SELECT 1 FROM ##WIA r2
          WHERE r2.collection_time = r.collection_time
            AND r2.blocking_session_id = r.session_id
            AND r2.blocking_session_id <> r2.session_id
      )
    
    UNION ALL
    
    -- Recursive Member: blocked sessions
    SELECT 
         r.*
        ,b.RecursionLevel + 1
        ,CAST(b.[LEVEL] + RIGHT('0000' + CAST(r.session_id AS VARCHAR(10)), 4) AS VARCHAR(1000))
    FROM ##WIA r
    INNER JOIN T_BLOCKERS b 
        ON r.collection_time = b.collection_time
       AND r.blocking_session_id = b.session_id
    WHERE r.blocking_session_id <> r.session_id
)
SELECT
    [BLOCKING_TREE] = N'    '
        + REPLICATE(N'|         ', RecursionLevel)
        + CASE WHEN RecursionLevel = 0 THEN 'HEAD -  ' ELSE '|------  ' END
        + CAST(session_id AS NVARCHAR(10)) + N' '
        + CASE WHEN LEFT(CleanData.batch_text, 1) = '('
               THEN SUBSTRING(CleanData.batch_text, CHARINDEX('exec', CleanData.batch_text), LEN(CleanData.batch_text))
               ELSE CleanData.batch_text END
    ,r.[dd hh:mm:ss.mss],      r.[wait_info],          r.[blocked_session_count]
    ,r.[blocking_session_id],  r.[login_name],         r.[host_name]
    ,r.[database_name],        r.[program_name],       r.[tempdb_allocations]
    ,r.[tempdb_current],       r.[reads],              r.[writes]
    ,r.[physical_reads],       r.[CPU],                r.[used_memory]
    ,r.[status],               r.[open_tran_count],    r.[percent_complete]
    ,r.[start_time],           r.[sql_command]
FROM T_BLOCKERS r
CROSS APPLY (
    SELECT [batch_text] = REPLACE(REPLACE(REPLACE(REPLACE(
                          CAST(COALESCE(r.[sql_command], r.[sql_text]) AS VARCHAR(MAX))
                          ,CHAR(13),''),CHAR(10),''),'<?query --',''),'--?>','')
) AS CleanData
ORDER BY r.collection_time, [LEVEL] ASC
OPTION (MAXRECURSION 100);

-- Cleanup
IF OBJECT_ID('tempdb..##WIA') IS NOT NULL DROP TABLE ##WIA;