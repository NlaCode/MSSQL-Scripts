DECLARE @files            INT = 8;              -- how many .bak files
DECLARE @maxtransfersize  BIGINT = 4194304;     -- how much do you plan do use

-- How much memory sql instance has
DECLARE @memTotalMB FLOAT = (
    SELECT (total_physical_memory_kb / 1024.0) 
    FROM sys.dm_os_sys_memory
);

DECLARE @memSqlMB FLOAT = (
    SELECT (committed_kb / 1024.0) 
    FROM sys.dm_os_sys_info
);

-- Restore Threads 
DECLARE @cpus INT = (SELECT cpu_count FROM sys.dm_os_sys_info);

-- Default SQL Server calculation
DECLARE @defaultBuffer INT = @files * @cpus;

-- Safe limit: not use more than 5% SQL Server Memory for buffers
DECLARE @maxsafe INT = FLOOR((@memSqlMB * 0.05 * 1024 * 1024) / @maxtransfersize);

SELECT 
    CAST(@memTotalMB AS DECIMAL(18, 2))                  AS total_memory_MB,
    CAST((@memTotalMB / 1024.0) AS DECIMAL(18, 2))       AS total_memory_GB,      
    CAST(@memSqlMB AS DECIMAL(18, 2))                    AS sql_server_memory_MB,
    CAST((@memSqlMB / 1024.0) AS DECIMAL(18, 2))         AS sql_server_memory_GB, 
    @cpus                                                AS cpus,
    @files                                               AS bak_files,
    @defaultBuffer                                       AS buffercount_default_sql,
    @maxsafe                                             AS buffercount_max_safe,
    -- Recommendation: lowest between default and safe limit
    CASE 
        WHEN @defaultBuffer <= @maxsafe THEN @defaultBuffer
        ELSE @maxsafe
    END                                                  AS recommended_buffercount,
    -- Memory which will be consumed (in MB)
    CAST((CASE 
        WHEN @defaultBuffer <= @maxsafe THEN @defaultBuffer
        ELSE @maxsafe
    END * CAST(@maxtransfersize AS FLOAT) / 1048576.0) AS DECIMAL(18, 2)) AS memory_buffers_MB,
    -- Memory which will be consumed (in GB)
    CAST((CASE 
        WHEN @defaultBuffer <= @maxsafe THEN @defaultBuffer
        ELSE @maxsafe
    END * CAST(@maxtransfersize AS FLOAT) / 1073741824.0) AS DECIMAL(18, 2)) AS memory_buffers_GB;