
-- Create statistics of an index
CREATE NONCLUSTERED INDEX xxxx ON <schema>.<tabela>(<coluna>)
WITH (STATISTICS_ONLY = -1)

-- Check the indexes
EXECUTE SP_HELPINDEX '<schema>.<tabela>'

--  Force the optimiser to take the index into account by filtering by its name.
DECLARE @dbid INT = DB_ID();
DECLARE @objectid INT = (SELECT id FROM sysindexes WHERE name = ' ');
DECLARE @indexid INT = (SELECT indid FROM sysindexes WHERE name = ' ');
DBCC AUTOPILOT(0, @dbid, @objectid, @indexid);

SET AUTOPILOT ON;

/* Test the query now */

/* disable everything and drop the hypothetical index */
SET AUTOPILOT OFF;

drop index xxx on <schema>.<table>
