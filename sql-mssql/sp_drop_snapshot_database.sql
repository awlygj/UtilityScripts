CREATE OR ALTER PROCEDURE sp_dropsnapshotdatabase
    @ori_db_name NVARCHAR(255),
    @dt DATETIME,
    @mode INT = 0 --0 list; 1 drop
AS
BEGIN

DECLARE @execsql NVARCHAR(MAX);
DECLARE @ss_db_name NVARCHAR(255);

DECLARE ss_db_name CURSOR FOR
    SELECT sd.name
    FROM sys.databases AS od
    INNER JOIN sys.databases AS sd
        ON od.database_id = sd.source_database_id
    WHERE od.name = @ori_db_name
      AND sd.is_read_only = 1
      AND sd.create_date < @dt
;

OPEN ss_db_name;

FETCH NEXT FROM ss_db_name
INTO @ss_db_name;

IF @@FETCH_STATUS <> 0
BEGIN
    RAISERROR('ORIGINAL DB NAME ERROR OR NOT EXISTS SNAPSHOT DATABASE!', 16, 1);
    CLOSE ss_db_name;
    DEALLOCATE ss_db_name;
    RETURN -1;
END

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @execsql = 'DROP DATABASE ' + @ss_db_name + ';';
    PRINT @execsql;
    IF @mode = 1
        EXECUTE(@execsql);

    FETCH NEXT FROM ss_db_name
    INTO @ss_db_name;
END

CLOSE ss_db_name;
DEALLOCATE ss_db_name;

RETURN 0;

END;
GO

