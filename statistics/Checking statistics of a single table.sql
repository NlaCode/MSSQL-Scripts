-- Checking table statistics
SELECT OBJECT_NAME(sp.object_id) AS 'Table',
sp.stats_id AS 'Statistic ID',
s.name AS 'Statistic',
c.name AS ColumnName,
sp.last_updated AS 'Last Updated',
sp.rows,
sp.rows_sampled,
CAST((sp.rows_sampled * 100.0 / NULLIF(sp.unfiltered_rows, 0)) AS NUMERIC(10,2)) AS [% sampled],
sp.unfiltered_rows,
sp.modification_counter AS 'Modifications',
(sqrt(1000 * sp.rows)) AS 'Approximate Update Threshold'
FROM sys.stats AS s
JOIN sys.stats_columns sc ON sc.object_id = s.object_id AND sc.stats_id = s.stats_id
OUTER APPLY sys.dm_db_stats_properties (s.object_id,s.stats_id) AS sp
JOIN sys.columns c ON c.object_id = sc.object_id AND c.column_id = sc.column_id
WHERE s.object_id = OBJECT_ID(N'<TABLE>')

-- Checking a single statistic
DBCC SHOW_STATISTICS ('<TABLE>', '<STATISTIC>')

-- Checking statistic auto-update
exec sp_autostats '<TABLE>'