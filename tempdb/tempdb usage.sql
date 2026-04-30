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