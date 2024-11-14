CREATE OR ALTER PROCEDURE sp_createsnapshotdatabase
    @db_name NVARCHAR(255)
AS
BEGIN

IF NOT EXISTS (
    SELECT *
    FROM sys.databases
    WHERE name = @db_name
      AND source_database_id IS NULL
      AND is_read_only = 0
)
BEGIN
    RAISERROR('DB NAME ERROR!', 16, 1);
    RETURN -1;
END

DECLARE @ss_db_name NVARCHAR(255);
SET @ss_db_name = @db_name + '_SS_' + FORMAT(GETDATE(), 'yyyyMMddHHmmss');

DECLARE @execsql_filelist NVARCHAR(MAX);
SELECT @execsql_filelist = TRIM(',' FROM STRING_AGG(CONVERT(NVARCHAR(MAX),
            '(NAME = ' + mf.name +
            ', FILENAME = ''E:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\' + @ss_db_name + '.mdf'')'), ','))
FROM master.sys.master_files AS mf
INNER JOIN sys.databases AS d
    ON mf.database_id = d.database_id
WHERE d.name = @db_name
  AND mf.type = 0
;

DECLARE @execsql NVARCHAR(MAX) = '';
SET @execsql = @execsql + N'
CREATE DATABASE ' + @ss_db_name + N'
ON ' + @execsql_filelist + N'
AS SNAPSHOT OF ' + @db_name + N';';

PRINT @execsql;
EXECUTE (@execsql);

RETURN 0;

END;
GO

