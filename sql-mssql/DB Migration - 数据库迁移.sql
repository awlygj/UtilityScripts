use master;
go

create table #restore_filelistonly (
    LogicalName          nvarchar(128),
    PhysicalName         nvarchar(260),
    Type                 char(1),
    FileGroupName        nvarchar(128),
    Size                 numeric(20,0),
    MaxSize              numeric(20,0),
    FileID               bigint,
    CreateLSN            numeric(25,0),
    DropLSN              numeric(25,0),
    UniqueID             uniqueidentifier,
    ReadOnlyLSN          numeric(25,0),
    ReadWriteLSN         numeric(25,0),
    BackupSizeInBytes    bigint,
    SourceBlockSize      int,
    FileGroupID          int,
    LogGroupGUID         uniqueidentifier,
    DifferentialBaseLSN  numeric(25,0),
    DifferentialBaseGUID uniqueidentifier,
    IsReadOnly           bit,
    IsPresent            bit,
    TDEThumbprint        varbinary(32),
    SnapshotURL          nvarchar(360)
);

create table #ST_DB_Migration_LIST (
    oserver nvarchar(255) not null,
    nserver nvarchar(255) not null,
    odb     nvarchar(255) not null,
    ndb     nvarchar(255) not null,
    primary key (nserver, ndb)
);

insert into #ST_DB_Migration_LIST values
('CNSISTWSQL050', 'CNSISTWSQL100', 'KAMI', 'KAMI'),
('cnsistwsql080', 'CNSISTWSQL100', 'DB_CATA_EXT_ST1', 'DB_CATA_EXT_ST1'),
('cnsistwsql080', 'CNSISTWSQL100', 'DB_CATA_ST1', 'DB_CATA_ST1'),
('cnsistwsql080', 'CNSISTWSQL100', 'DB_DC1_ST1', 'DB_DC1_ST1'),
('cnsistwsql080', 'CNSISTWSQL100', 'DB_IWS_GNL_ST1', 'DB_IWS_GNL_ST1'),
('cnsistwsql080', 'CNSISTWSQL100', 'DB_IWS_SCAN_ST1', 'DB_IWS_SCAN_ST1'),
('cnsistwsql080', 'CNSISTWSQL100', 'DB_SIGN_ST1', 'DB_SIGN_ST1'),
('CNDCDWSQL90', 'CNSISTWSQL100', 'DB_CATA_EXT', 'DB_CATA_EXT_ST2'),
('CNDCDWSQL90', 'CNSISTWSQL100', 'DB_CATA', 'DB_CATA_ST2'),
('CNDCDWSQL90', 'CNSISTWSQL100', 'DB_DC1', 'DB_DC1_ST2'),
('CNDCDWSQL90', 'CNSISTWSQL100', 'DB_IWS_GNL', 'DB_IWS_GNL_ST2'),
('CNDCDWSQL90', 'CNSISTWSQL100', 'DB_IWS_SCAN', 'DB_IWS_SCAN_ST2'),
('CNDCDWSQL90', 'CNSISTWSQL100', 'DB_SIGN', 'DB_SIGN_ST2'),
('cnsistwsql070', 'CNSISTWSQL100', 'DB_CATA_EXT_ST3', 'DB_CATA_EXT_ST3'),
('cnsistwsql070', 'CNSISTWSQL100', 'DB_CATA_ST3', 'DB_CATA_ST3'),
('cnsistwsql070', 'CNSISTWSQL100', 'DB_DC1_ST3', 'DB_DC1_ST3'),
('cnsistwsql070', 'CNSISTWSQL100', 'DB_IWS_GNL_ST3', 'DB_IWS_GNL_ST3'),
('cnsistwsql070', 'CNSISTWSQL100', 'DB_IWS_SCAN_ST3', 'DB_IWS_SCAN_ST3'),
('cnsistwsql070', 'CNSISTWSQL100', 'DB_SIGN_ST3', 'DB_SIGN_ST3');
--('CNACLTWCPD403S', 'CNSISTWSQL100', 'DB_CATA', 'DB_CATA_st4'),
--('CNACLTWCPD403S', 'CNSISTWSQL100', 'DB_CATA_EXT', 'DB_CATA_EXT_st4'),
--('CNACLTWCPD403S', 'CNSISTWSQL100', 'DB_DC1', 'DB_DC1_st4'),
--('CNACLTWCPD403S', 'CNSISTWSQL100', 'DB_IWS_GNL', 'DB_IWS_GNL_st4'),
--('CNACLTWCPD403S', 'CNSISTWSQL100', 'DB_IWS_SCAN', 'DB_IWS_SCAN_st4'),
--('CNACLTWCPD403S', 'CNSISTWSQL100', 'DB_SIGN', 'DB_SIGN_st4'),
--('CNACLTWCPD403S', 'CNSISTWSQL100', 'db_hfv_st4', 'DB_HFV_ST1'),
--('CNACLTWCPD403S', 'CNSISTWSQL100', 'db_hfv_st4', 'DB_HFV_ST2'),
--('CNACLTWCPD403S', 'CNSISTWSQL100', 'db_hfv_st4', 'db_hfv_st3'),
--('CNACLTWCPD403S', 'CNSISTWSQL100', 'db_hfv_st4', 'db_hfv_st4');

declare @run_mode  varchar(255) = 'backup';    --backup; restore
declare @view_only int = 1;

declare @bak_path nvarchar(max) = '\\cnsistwscl020\Newsis Backup\FullBackup\';
declare @bak_type nvarchar(max) = '_full_backup';
declare @bak_dt   nvarchar(max) = '_2025_04_09_16_02_28';    --select format(getdate(), '_yyyy_MM_dd_HH_mm_ss');
declare @bak_ext  nvarchar(max) = '.bak';
declare @bak_desc nvarchar(max) = 'ST DB Migration';

declare @data_path nvarchar(max) = 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\';

declare @exec_sql nvarchar(max);

declare @oserver nvarchar(max);
declare @nserver nvarchar(max);
declare @odb     nvarchar(max);
declare @ndb     nvarchar(max);

declare @prev_oserver nvarchar(max);
declare @prev_odb     nvarchar(max);

declare ST_DB_Migration_LIST cursor for
    select *
    from #ST_DB_Migration_LIST
    order by oserver, odb, nserver, ndb;

open ST_DB_Migration_LIST;

fetch next from ST_DB_Migration_LIST
into @oserver, @nserver, @odb, @ndb;

while @@fetch_status = 0
begin
    if @run_mode = 'backup'
    begin
        if @oserver = @@servername
        begin
            if (@prev_oserver = @oserver and @prev_odb = @odb)
            begin
                set @exec_sql = '';
            end
            else
            begin
                print '* backup: server[' + @oserver + '], database[' + @odb + ']';

                set @exec_sql = N'\
backup database ' + @odb + N'
to disk = ''' + @bak_path + @oserver + N'_' + @odb + @bak_type + @bak_dt + @bak_ext + N'''
with compression,
     description = ''' + @bak_desc + N''',
     name = ''' + @oserver + N'_' + @odb + @bak_type + @bak_dt + N''',
     mediadescription = ''' + @bak_desc + N''',
     medianame = ''' + @oserver + N'_' + @odb + @bak_type + @bak_dt + N''',
     format,
     stats = 20;';

                set @prev_oserver = @oserver;
                set @prev_odb = @odb;
            end
        end
        else
        begin
            set @exec_sql = '';
        end
    end
    else if @run_mode = 'restore'
    begin
        if @nserver = @@servername
        begin
            print '* restore: server[' + @oserver + ']>>[' + @nserver + '], database[' + @odb + ']>>[' + @ndb + ']';

            truncate table #restore_filelistonly;
            insert into #restore_filelistonly
            execute (N'\
RESTORE FILELISTONLY
FROM DISK = ''' + @bak_path + @oserver + N'_' + @odb + @bak_type + @bak_dt + @bak_ext + N'''
WITH FILE = 1,
     MEDIANAME = ''' + @oserver + N'_' + @odb + @bak_type + @bak_dt + N''';');

            set @exec_sql = N'\
restore database ' + @ndb + N'
from disk = ''' + @bak_path + @oserver + N'_' + @odb + @bak_type + @bak_dt + @bak_ext + N'''
with recovery,
' + (select string_agg(cast(N'     move ''' + LogicalName +
                                N''' to ''' + @data_path + @ndb + TailName +
                            N''',' as nvarchar(max)),
                       char(13) + char(10))
     from (
        select LogicalName,
               case when Type = 'D' and FId = 1 then '.mdf'
                    when Type = 'L' and FId = 1 then '_log.ldf'
                    when Type = 'D' then concat('_', FId, '.ndf')
                    when Type = 'L' then concat('_', FId, '_log.ldf')
               end as TailName
        from (
            select *, row_number() over(partition by Type order by FileID) as FId
            from #restore_filelistonly
        ) as t
     ) as t
    ) + N'
     file = 1,
     medianame = ''' + @oserver + N'_' + @odb + @bak_type + @bak_dt + N''',
     stats = 20;';

        end
        else
        begin
            set @exec_sql = '';
        end
    end

    if isnull(@exec_sql, '') <> ''
    begin
        print '* run sql:';
        print @exec_sql;

        if @view_only = 1
            print '* view only, sql not execute';
        else
            execute(@exec_sql);

        print '* run end';
        print '';
    end

    fetch next from ST_DB_Migration_LIST
    into @oserver, @nserver, @odb, @ndb;
end

close ST_DB_Migration_LIST;
deallocate ST_DB_Migration_LIST;

select t.*, d.name, d.state_desc, d.user_access_desc, d.recovery_model_desc, d.is_encrypted, d.is_master_key_encrypted_by_server
from #ST_DB_Migration_LIST as t
left outer join sys.databases as d
    on iif(@run_mode = 'backup', t.odb, t.ndb) = d.name
where iif(@run_mode = 'backup', t.oserver, t.nserver) = @@servername;

drop table #restore_filelistonly;
drop table #ST_DB_Migration_LIST;
go

select name, compatibility_level, 'ALTER DATABASE ' + name + ' SET COMPATIBILITY_LEVEL = 160;'
from sys.databases
where name not in ('master', 'tempdb', 'model', 'msdb')
order by name;

select d.name, mf.*
from sys.master_files as mf
inner join sys.databases as d
    on mf.database_id = d.database_id
where d.name not in ('master', 'tempdb', 'model', 'msdb')
order by d.name;


/*
Warning! The maximum key length for a nonclustered index is 1700 bytes. The index 'UQ__#ST_DB_M__D5DCD2AA110F8DAF' has maximum length of 2040 bytes. For some combination of large values, the insert/update operation will fail.

(29 rows affected)
* backup: server[CNSISTWSQL050], database[KAMI]
* run sql:
backup database KAMI
to disk = '\\cnsistwscl020\Newsis Backup\FullBackup\CNSISTWSQL050_KAMI_full_backup_2025_04_09_16_02_28.bak'
with compression,
     description = 'ST DB Migration',
     name = 'CNSISTWSQL050_KAMI_full_backup_2025_04_09_16_02_28',
     mediadescription = 'ST DB Migration',
     medianame = 'CNSISTWSQL050_KAMI_full_backup_2025_04_09_16_02_28',
     format,
     stats = 20;
20 percent processed.
40 percent processed.
60 percent processed.
80 percent processed.
100 percent processed.
Processed 337304 pages for database 'KAMI', file 'Kami' on file 1.
Processed 1 pages for database 'KAMI', file 'Kami_log' on file 1.
BACKUP DATABASE successfully processed 337305 pages in 37.766 seconds (69.776 MB/sec).
* run end
 

(1 row affected)

Completion time: 2025-04-09T16:03:50.6313080+08:00







Warning! The maximum key length for a nonclustered index is 1700 bytes. The index 'UQ__#ST_DB_M__D5DCD2AADE53266F' has maximum length of 2040 bytes. For some combination of large values, the insert/update operation will fail.

(29 rows affected)
* backup: server[cnsistwsql080], database[DB_CATA_EXT_ST1]
* run sql:
backup database DB_CATA_EXT_ST1
to disk = '\\cnsistwscl020\Newsis Backup\FullBackup\cnsistwsql080_DB_CATA_EXT_ST1_full_backup_2025_04_09_16_02_28.bak'
with compression,
     description = 'ST DB Migration',
     name = 'cnsistwsql080_DB_CATA_EXT_ST1_full_backup_2025_04_09_16_02_28',
     mediadescription = 'ST DB Migration',
     medianame = 'cnsistwsql080_DB_CATA_EXT_ST1_full_backup_2025_04_09_16_02_28',
     format,
     stats = 20;
20 percent processed.
40 percent processed.
60 percent processed.
80 percent processed.
100 percent processed.
Processed 13344 pages for database 'DB_CATA_EXT_ST1', file 'DB_CATA_EXT_Data' on file 1.
Processed 1 pages for database 'DB_CATA_EXT_ST1', file 'DB_CATA_EXT_Log' on file 1.
BACKUP DATABASE successfully processed 13345 pages in 1.698 seconds (61.396 MB/sec).
* run end
 
* backup: server[cnsistwsql080], database[DB_CATA_ST1]
* run sql:
backup database DB_CATA_ST1
to disk = '\\cnsistwscl020\Newsis Backup\FullBackup\cnsistwsql080_DB_CATA_ST1_full_backup_2025_04_09_16_02_28.bak'
with compression,
     description = 'ST DB Migration',
     name = 'cnsistwsql080_DB_CATA_ST1_full_backup_2025_04_09_16_02_28',
     mediadescription = 'ST DB Migration',
     medianame = 'cnsistwsql080_DB_CATA_ST1_full_backup_2025_04_09_16_02_28',
     format,
     stats = 20;
20 percent processed.
40 percent processed.
60 percent processed.
80 percent processed.
100 percent processed.
Processed 960 pages for database 'DB_CATA_ST1', file 'DB_CATA_Data' on file 1.
Processed 1 pages for database 'DB_CATA_ST1', file 'DB_CATA_log' on file 1.
BACKUP DATABASE successfully processed 961 pages in 0.320 seconds (23.442 MB/sec).
* run end
 
* backup: server[cnsistwsql080], database[DB_DC1_ST1]
* run sql:
backup database DB_DC1_ST1
to disk = '\\cnsistwscl020\Newsis Backup\FullBackup\cnsistwsql080_DB_DC1_ST1_full_backup_2025_04_09_16_02_28.bak'
with compression,
     description = 'ST DB Migration',
     name = 'cnsistwsql080_DB_DC1_ST1_full_backup_2025_04_09_16_02_28',
     mediadescription = 'ST DB Migration',
     medianame = 'cnsistwsql080_DB_DC1_ST1_full_backup_2025_04_09_16_02_28',
     format,
     stats = 20;
20 percent processed.
40 percent processed.
60 percent processed.
80 percent processed.
100 percent processed.
Processed 107448 pages for database 'DB_DC1_ST1', file 'DB_DC1_Data' on file 1.
Processed 1 pages for database 'DB_DC1_ST1', file 'DB_DC1_log' on file 1.
BACKUP DATABASE successfully processed 107449 pages in 8.440 seconds (99.459 MB/sec).
* run end
 
* backup: server[cnsistwsql080], database[DB_IWS_GNL_ST1]
* run sql:
backup database DB_IWS_GNL_ST1
to disk = '\\cnsistwscl020\Newsis Backup\FullBackup\cnsistwsql080_DB_IWS_GNL_ST1_full_backup_2025_04_09_16_02_28.bak'
with compression,
     description = 'ST DB Migration',
     name = 'cnsistwsql080_DB_IWS_GNL_ST1_full_backup_2025_04_09_16_02_28',
     mediadescription = 'ST DB Migration',
     medianame = 'cnsistwsql080_DB_IWS_GNL_ST1_full_backup_2025_04_09_16_02_28',
     format,
     stats = 20;
20 percent processed.
40 percent processed.
60 percent processed.
80 percent processed.
100 percent processed.
Processed 22096 pages for database 'DB_IWS_GNL_ST1', file 'DB_IWS_GNL_Data' on file 1.
Processed 1 pages for database 'DB_IWS_GNL_ST1', file 'DB_IWS_GNL_Log' on file 1.
BACKUP DATABASE successfully processed 22097 pages in 2.423 seconds (71.245 MB/sec).
* run end
 
* backup: server[cnsistwsql080], database[DB_IWS_SCAN_ST1]
* run sql:
backup database DB_IWS_SCAN_ST1
to disk = '\\cnsistwscl020\Newsis Backup\FullBackup\cnsistwsql080_DB_IWS_SCAN_ST1_full_backup_2025_04_09_16_02_28.bak'
with compression,
     description = 'ST DB Migration',
     name = 'cnsistwsql080_DB_IWS_SCAN_ST1_full_backup_2025_04_09_16_02_28',
     mediadescription = 'ST DB Migration',
     medianame = 'cnsistwsql080_DB_IWS_SCAN_ST1_full_backup_2025_04_09_16_02_28',
     format,
     stats = 20;
20 percent processed.
40 percent processed.
60 percent processed.
80 percent processed.
100 percent processed.
Processed 132664 pages for database 'DB_IWS_SCAN_ST1', file 'DB_IWS_SCAN' on file 1.
Processed 1 pages for database 'DB_IWS_SCAN_ST1', file 'DB_IWS_SCAN_log' on file 1.
BACKUP DATABASE successfully processed 132665 pages in 12.476 seconds (83.074 MB/sec).
* run end
 
* backup: server[cnsistwsql080], database[DB_SIGN_ST1]
* run sql:
backup database DB_SIGN_ST1
to disk = '\\cnsistwscl020\Newsis Backup\FullBackup\cnsistwsql080_DB_SIGN_ST1_full_backup_2025_04_09_16_02_28.bak'
with compression,
     description = 'ST DB Migration',
     name = 'cnsistwsql080_DB_SIGN_ST1_full_backup_2025_04_09_16_02_28',
     mediadescription = 'ST DB Migration',
     medianame = 'cnsistwsql080_DB_SIGN_ST1_full_backup_2025_04_09_16_02_28',
     format,
     stats = 20;
20 percent processed.
40 percent processed.
60 percent processed.
80 percent processed.
100 percent processed.
Processed 86552 pages for database 'DB_SIGN_ST1', file 'DB_SIGN_Data' on file 1.
Processed 1 pages for database 'DB_SIGN_ST1', file 'DB_SIGN_Log' on file 1.
BACKUP DATABASE successfully processed 86553 pages in 5.154 seconds (131.196 MB/sec).
* run end
 

(6 rows affected)

Completion time: 2025-04-09T16:06:30.2176970+08:00







Warning! The maximum key length for a nonclustered index is 1700 bytes. The index 'UQ__#ST_DB_M__D5DCD2AAFA99C526' has maximum length of 2040 bytes. For some combination of large values, the insert/update operation will fail.

(29 rows affected)
* backup: server[CNDCDWSQL90], database[DB_CATA]
* run sql:
backup database DB_CATA
to disk = '\\cnsistwscl020\Newsis Backup\FullBackup\CNDCDWSQL90_DB_CATA_full_backup_2025_04_09_16_02_28.bak'
with compression,
     description = 'ST DB Migration',
     name = 'CNDCDWSQL90_DB_CATA_full_backup_2025_04_09_16_02_28',
     mediadescription = 'ST DB Migration',
     medianame = 'CNDCDWSQL90_DB_CATA_full_backup_2025_04_09_16_02_28',
     format,
     stats = 20;
20 percent processed.
40 percent processed.
61 percent processed.
80 percent processed.
100 percent processed.
Processed 8584 pages for database 'DB_CATA', file 'DB_CATA_Data' on file 1.
Processed 1 pages for database 'DB_CATA', file 'DB_CATA_log' on file 1.
BACKUP DATABASE successfully processed 8585 pages in 0.604 seconds (111.033 MB/sec).
* run end
 
* backup: server[CNDCDWSQL90], database[DB_CATA_EXT]
* run sql:
backup database DB_CATA_EXT
to disk = '\\cnsistwscl020\Newsis Backup\FullBackup\CNDCDWSQL90_DB_CATA_EXT_full_backup_2025_04_09_16_02_28.bak'
with compression,
     description = 'ST DB Migration',
     name = 'CNDCDWSQL90_DB_CATA_EXT_full_backup_2025_04_09_16_02_28',
     mediadescription = 'ST DB Migration',
     medianame = 'CNDCDWSQL90_DB_CATA_EXT_full_backup_2025_04_09_16_02_28',
     format,
     stats = 20;
20 percent processed.
40 percent processed.
60 percent processed.
80 percent processed.
100 percent processed.
Processed 200608 pages for database 'DB_CATA_EXT', file 'DB_CATA_EXT_Data' on file 1.
Processed 1 pages for database 'DB_CATA_EXT', file 'DB_CATA_EXT_Log' on file 1.
BACKUP DATABASE successfully processed 200609 pages in 11.162 seconds (140.409 MB/sec).
* run end
 
* backup: server[CNDCDWSQL90], database[DB_DC1]
* run sql:
backup database DB_DC1
to disk = '\\cnsistwscl020\Newsis Backup\FullBackup\CNDCDWSQL90_DB_DC1_full_backup_2025_04_09_16_02_28.bak'
with compression,
     description = 'ST DB Migration',
     name = 'CNDCDWSQL90_DB_DC1_full_backup_2025_04_09_16_02_28',
     mediadescription = 'ST DB Migration',
     medianame = 'CNDCDWSQL90_DB_DC1_full_backup_2025_04_09_16_02_28',
     format,
     stats = 20;
20 percent processed.
40 percent processed.
60 percent processed.
80 percent processed.
100 percent processed.
Processed 98872 pages for database 'DB_DC1', file 'DB_DC1_Data' on file 1.
Processed 1 pages for database 'DB_DC1', file 'DB_DC1_log' on file 1.
BACKUP DATABASE successfully processed 98873 pages in 6.306 seconds (122.492 MB/sec).
* run end
 
* backup: server[CNDCDWSQL90], database[DB_IWS_GNL]
* run sql:
backup database DB_IWS_GNL
to disk = '\\cnsistwscl020\Newsis Backup\FullBackup\CNDCDWSQL90_DB_IWS_GNL_full_backup_2025_04_09_16_02_28.bak'
with compression,
     description = 'ST DB Migration',
     name = 'CNDCDWSQL90_DB_IWS_GNL_full_backup_2025_04_09_16_02_28',
     mediadescription = 'ST DB Migration',
     medianame = 'CNDCDWSQL90_DB_IWS_GNL_full_backup_2025_04_09_16_02_28',
     format,
     stats = 20;
20 percent processed.
40 percent processed.
60 percent processed.
80 percent processed.
100 percent processed.
Processed 27512 pages for database 'DB_IWS_GNL', file 'DB_IWS_GNL_Data' on file 1.
Processed 1 pages for database 'DB_IWS_GNL', file 'DB_IWS_GNL_Log' on file 1.
BACKUP DATABASE successfully processed 27513 pages in 2.321 seconds (92.606 MB/sec).
* run end
 
* backup: server[CNDCDWSQL90], database[DB_IWS_SCAN]
* run sql:
backup database DB_IWS_SCAN
to disk = '\\cnsistwscl020\Newsis Backup\FullBackup\CNDCDWSQL90_DB_IWS_SCAN_full_backup_2025_04_09_16_02_28.bak'
with compression,
     description = 'ST DB Migration',
     name = 'CNDCDWSQL90_DB_IWS_SCAN_full_backup_2025_04_09_16_02_28',
     mediadescription = 'ST DB Migration',
     medianame = 'CNDCDWSQL90_DB_IWS_SCAN_full_backup_2025_04_09_16_02_28',
     format,
     stats = 20;
20 percent processed.
40 percent processed.
60 percent processed.
80 percent processed.
100 percent processed.
Processed 153048 pages for database 'DB_IWS_SCAN', file 'DB_IWS_SCAN' on file 1.
Processed 1 pages for database 'DB_IWS_SCAN', file 'DB_IWS_SCAN_log' on file 1.
BACKUP DATABASE successfully processed 153049 pages in 10.746 seconds (111.268 MB/sec).
* run end
 
* backup: server[CNDCDWSQL90], database[DB_SIGN]
* run sql:
backup database DB_SIGN
to disk = '\\cnsistwscl020\Newsis Backup\FullBackup\CNDCDWSQL90_DB_SIGN_full_backup_2025_04_09_16_02_28.bak'
with compression,
     description = 'ST DB Migration',
     name = 'CNDCDWSQL90_DB_SIGN_full_backup_2025_04_09_16_02_28',
     mediadescription = 'ST DB Migration',
     medianame = 'CNDCDWSQL90_DB_SIGN_full_backup_2025_04_09_16_02_28',
     format,
     stats = 20;
20 percent processed.
40 percent processed.
60 percent processed.
80 percent processed.
100 percent processed.
Processed 13416 pages for database 'DB_SIGN', file 'DB_SIGN_Data' on file 1.
Processed 1 pages for database 'DB_SIGN', file 'DB_SIGN_Log' on file 1.
BACKUP DATABASE successfully processed 13417 pages in 1.423 seconds (73.657 MB/sec).
* run end
 

(6 rows affected)

Completion time: 2025-04-09T16:09:18.7488879+08:00









Warning! The maximum key length for a nonclustered index is 1700 bytes. The index 'UQ__#ST_DB_M__D5DCD2AA86833458' has maximum length of 2040 bytes. For some combination of large values, the insert/update operation will fail.

(29 rows affected)
* backup: server[cnsistwsql070], database[DB_CATA_EXT_ST3]
* run sql:
backup database DB_CATA_EXT_ST3
to disk = '\\cnsistwscl020\Newsis Backup\FullBackup\cnsistwsql070_DB_CATA_EXT_ST3_full_backup_2025_04_09_16_02_28.bak'
with compression,
     description = 'ST DB Migration',
     name = 'cnsistwsql070_DB_CATA_EXT_ST3_full_backup_2025_04_09_16_02_28',
     mediadescription = 'ST DB Migration',
     medianame = 'cnsistwsql070_DB_CATA_EXT_ST3_full_backup_2025_04_09_16_02_28',
     format,
     stats = 20;
20 percent processed.
40 percent processed.
60 percent processed.
80 percent processed.
100 percent processed.
Processed 16136 pages for database 'DB_CATA_EXT_ST3', file 'DB_CATA_EXT_Data' on file 1.
Processed 1 pages for database 'DB_CATA_EXT_ST3', file 'DB_CATA_EXT_Log' on file 1.
BACKUP DATABASE successfully processed 16137 pages in 1.757 seconds (71.749 MB/sec).
* run end
 
* backup: server[cnsistwsql070], database[DB_CATA_ST3]
* run sql:
backup database DB_CATA_ST3
to disk = '\\cnsistwscl020\Newsis Backup\FullBackup\cnsistwsql070_DB_CATA_ST3_full_backup_2025_04_09_16_02_28.bak'
with compression,
     description = 'ST DB Migration',
     name = 'cnsistwsql070_DB_CATA_ST3_full_backup_2025_04_09_16_02_28',
     mediadescription = 'ST DB Migration',
     medianame = 'cnsistwsql070_DB_CATA_ST3_full_backup_2025_04_09_16_02_28',
     format,
     stats = 20;
26 percent processed.
46 percent processed.
61 percent processed.
86 percent processed.
100 percent processed.
Processed 1960 pages for database 'DB_CATA_ST3', file 'DB_CATA_Data' on file 1.
Processed 1 pages for database 'DB_CATA_ST3', file 'DB_CATA_log' on file 1.
BACKUP DATABASE successfully processed 1961 pages in 0.412 seconds (37.169 MB/sec).
* run end
 
* backup: server[cnsistwsql070], database[DB_DC1_ST3]
* run sql:
backup database DB_DC1_ST3
to disk = '\\cnsistwscl020\Newsis Backup\FullBackup\cnsistwsql070_DB_DC1_ST3_full_backup_2025_04_09_16_02_28.bak'
with compression,
     description = 'ST DB Migration',
     name = 'cnsistwsql070_DB_DC1_ST3_full_backup_2025_04_09_16_02_28',
     mediadescription = 'ST DB Migration',
     medianame = 'cnsistwsql070_DB_DC1_ST3_full_backup_2025_04_09_16_02_28',
     format,
     stats = 20;
20 percent processed.
40 percent processed.
60 percent processed.
80 percent processed.
100 percent processed.
Processed 188832 pages for database 'DB_DC1_ST3', file 'DB_DC1_Data' on file 1.
Processed 1 pages for database 'DB_DC1_ST3', file 'DB_DC1_log' on file 1.
BACKUP DATABASE successfully processed 188833 pages in 15.657 seconds (94.223 MB/sec).
* run end
 
* backup: server[cnsistwsql070], database[DB_IWS_GNL_ST3]
* run sql:
backup database DB_IWS_GNL_ST3
to disk = '\\cnsistwscl020\Newsis Backup\FullBackup\cnsistwsql070_DB_IWS_GNL_ST3_full_backup_2025_04_09_16_02_28.bak'
with compression,
     description = 'ST DB Migration',
     name = 'cnsistwsql070_DB_IWS_GNL_ST3_full_backup_2025_04_09_16_02_28',
     mediadescription = 'ST DB Migration',
     medianame = 'cnsistwsql070_DB_IWS_GNL_ST3_full_backup_2025_04_09_16_02_28',
     format,
     stats = 20;
20 percent processed.
40 percent processed.
60 percent processed.
80 percent processed.
100 percent processed.
Processed 23160 pages for database 'DB_IWS_GNL_ST3', file 'DB_IWS_GNL_Data' on file 1.
Processed 1 pages for database 'DB_IWS_GNL_ST3', file 'DB_IWS_GNL_Log' on file 1.
BACKUP DATABASE successfully processed 23161 pages in 1.787 seconds (101.253 MB/sec).
* run end
 
* backup: server[cnsistwsql070], database[DB_IWS_SCAN_ST3]
* run sql:
backup database DB_IWS_SCAN_ST3
to disk = '\\cnsistwscl020\Newsis Backup\FullBackup\cnsistwsql070_DB_IWS_SCAN_ST3_full_backup_2025_04_09_16_02_28.bak'
with compression,
     description = 'ST DB Migration',
     name = 'cnsistwsql070_DB_IWS_SCAN_ST3_full_backup_2025_04_09_16_02_28',
     mediadescription = 'ST DB Migration',
     medianame = 'cnsistwsql070_DB_IWS_SCAN_ST3_full_backup_2025_04_09_16_02_28',
     format,
     stats = 20;
20 percent processed.
40 percent processed.
60 percent processed.
80 percent processed.
100 percent processed.
Processed 140080 pages for database 'DB_IWS_SCAN_ST3', file 'DB_IWS_SCAN' on file 1.
Processed 1 pages for database 'DB_IWS_SCAN_ST3', file 'DB_IWS_SCAN_log' on file 1.
BACKUP DATABASE successfully processed 140081 pages in 8.360 seconds (130.906 MB/sec).
* run end
 
* backup: server[cnsistwsql070], database[DB_SIGN_ST3]
* run sql:
backup database DB_SIGN_ST3
to disk = '\\cnsistwscl020\Newsis Backup\FullBackup\cnsistwsql070_DB_SIGN_ST3_full_backup_2025_04_09_16_02_28.bak'
with compression,
     description = 'ST DB Migration',
     name = 'cnsistwsql070_DB_SIGN_ST3_full_backup_2025_04_09_16_02_28',
     mediadescription = 'ST DB Migration',
     medianame = 'cnsistwsql070_DB_SIGN_ST3_full_backup_2025_04_09_16_02_28',
     format,
     stats = 20;
20 percent processed.
40 percent processed.
60 percent processed.
80 percent processed.
100 percent processed.
Processed 54560 pages for database 'DB_SIGN_ST3', file 'DB_SIGN_Data' on file 1.
Processed 1 pages for database 'DB_SIGN_ST3', file 'DB_SIGN_Log' on file 1.
BACKUP DATABASE successfully processed 54561 pages in 4.193 seconds (101.657 MB/sec).
* run end
 

(6 rows affected)

Completion time: 2025-04-09T16:13:16.6958744+08:00











Warning! The maximum key length for a nonclustered index is 1700 bytes. The index 'UQ__#ST_DB_M__D5DCD2AA6AE956B0' has maximum length of 2040 bytes. For some combination of large values, the insert/update operation will fail.

(19 rows affected)
* restore: server[CNDCDWSQL90]>>[CNSISTWSQL100], database[DB_CATA]>>[DB_CATA_ST2]

(2 rows affected)
* run sql:
restore database DB_CATA_ST2
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\CNDCDWSQL90_DB_CATA_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'DB_CATA_Data' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_CATA_ST2.mdf',
     move 'DB_CATA_log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_CATA_ST2_log.ldf',
     file = 1,
     medianame = 'CNDCDWSQL90_DB_CATA_full_backup_2025_04_09_16_02_28',
     stats = 1;
1 percent processed.
2 percent processed.
4 percent processed.
5 percent processed.
7 percent processed.
8 percent processed.
10 percent processed.
11 percent processed.
13 percent processed.
14 percent processed.
16 percent processed.
17 percent processed.
19 percent processed.
20 percent processed.
22 percent processed.
23 percent processed.
25 percent processed.
26 percent processed.
28 percent processed.
29 percent processed.
31 percent processed.
32 percent processed.
34 percent processed.
35 percent processed.
37 percent processed.
38 percent processed.
40 percent processed.
41 percent processed.
43 percent processed.
44 percent processed.
46 percent processed.
47 percent processed.
49 percent processed.
50 percent processed.
52 percent processed.
53 percent processed.
55 percent processed.
56 percent processed.
58 percent processed.
59 percent processed.
61 percent processed.
62 percent processed.
64 percent processed.
65 percent processed.
67 percent processed.
68 percent processed.
70 percent processed.
71 percent processed.
73 percent processed.
74 percent processed.
76 percent processed.
77 percent processed.
79 percent processed.
80 percent processed.
82 percent processed.
83 percent processed.
85 percent processed.
86 percent processed.
88 percent processed.
89 percent processed.
91 percent processed.
92 percent processed.
94 percent processed.
95 percent processed.
97 percent processed.
98 percent processed.
100 percent processed.
Processed 8584 pages for database 'DB_CATA_ST2', file 'DB_CATA_Data' on file 1.
Processed 1 pages for database 'DB_CATA_ST2', file 'DB_CATA_log' on file 1.
Converting database 'DB_CATA_ST2' from version 904 to the current version 957.
Database 'DB_CATA_ST2' running the upgrade step from version 904 to version 905.
Database 'DB_CATA_ST2' running the upgrade step from version 905 to version 906.
Database 'DB_CATA_ST2' running the upgrade step from version 906 to version 907.
Database 'DB_CATA_ST2' running the upgrade step from version 907 to version 908.
Database 'DB_CATA_ST2' running the upgrade step from version 908 to version 909.
Database 'DB_CATA_ST2' running the upgrade step from version 909 to version 910.
Database 'DB_CATA_ST2' running the upgrade step from version 910 to version 911.
Database 'DB_CATA_ST2' running the upgrade step from version 911 to version 912.
Database 'DB_CATA_ST2' running the upgrade step from version 912 to version 913.
Database 'DB_CATA_ST2' running the upgrade step from version 913 to version 914.
Database 'DB_CATA_ST2' running the upgrade step from version 914 to version 915.
Database 'DB_CATA_ST2' running the upgrade step from version 915 to version 916.
Database 'DB_CATA_ST2' running the upgrade step from version 916 to version 917.
Database 'DB_CATA_ST2' running the upgrade step from version 917 to version 918.
Database 'DB_CATA_ST2' running the upgrade step from version 918 to version 919.
Database 'DB_CATA_ST2' running the upgrade step from version 919 to version 920.
Database 'DB_CATA_ST2' running the upgrade step from version 920 to version 921.
Database 'DB_CATA_ST2' running the upgrade step from version 921 to version 922.
Database 'DB_CATA_ST2' running the upgrade step from version 922 to version 923.
Database 'DB_CATA_ST2' running the upgrade step from version 923 to version 924.
Database 'DB_CATA_ST2' running the upgrade step from version 924 to version 925.
Database 'DB_CATA_ST2' running the upgrade step from version 925 to version 926.
Database 'DB_CATA_ST2' running the upgrade step from version 926 to version 927.
Database 'DB_CATA_ST2' running the upgrade step from version 927 to version 928.
Database 'DB_CATA_ST2' running the upgrade step from version 928 to version 929.
Database 'DB_CATA_ST2' running the upgrade step from version 929 to version 930.
Database 'DB_CATA_ST2' running the upgrade step from version 930 to version 931.
Database 'DB_CATA_ST2' running the upgrade step from version 931 to version 932.
Database 'DB_CATA_ST2' running the upgrade step from version 932 to version 933.
Database 'DB_CATA_ST2' running the upgrade step from version 933 to version 934.
Database 'DB_CATA_ST2' running the upgrade step from version 934 to version 935.
Database 'DB_CATA_ST2' running the upgrade step from version 935 to version 936.
Database 'DB_CATA_ST2' running the upgrade step from version 936 to version 937.
Database 'DB_CATA_ST2' running the upgrade step from version 937 to version 938.
Database 'DB_CATA_ST2' running the upgrade step from version 938 to version 939.
Database 'DB_CATA_ST2' running the upgrade step from version 939 to version 940.
Database 'DB_CATA_ST2' running the upgrade step from version 940 to version 941.
Database 'DB_CATA_ST2' running the upgrade step from version 941 to version 942.
Database 'DB_CATA_ST2' running the upgrade step from version 942 to version 943.
Database 'DB_CATA_ST2' running the upgrade step from version 943 to version 944.
Database 'DB_CATA_ST2' running the upgrade step from version 944 to version 945.
Database 'DB_CATA_ST2' running the upgrade step from version 945 to version 946.
Database 'DB_CATA_ST2' running the upgrade step from version 946 to version 947.
Database 'DB_CATA_ST2' running the upgrade step from version 947 to version 948.
Database 'DB_CATA_ST2' running the upgrade step from version 948 to version 949.
Database 'DB_CATA_ST2' running the upgrade step from version 949 to version 950.
Database 'DB_CATA_ST2' running the upgrade step from version 950 to version 951.
Database 'DB_CATA_ST2' running the upgrade step from version 951 to version 952.
Database 'DB_CATA_ST2' running the upgrade step from version 952 to version 953.
Database 'DB_CATA_ST2' running the upgrade step from version 953 to version 954.
Database 'DB_CATA_ST2' running the upgrade step from version 954 to version 955.
Database 'DB_CATA_ST2' running the upgrade step from version 955 to version 956.
Database 'DB_CATA_ST2' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 8585 pages in 0.500 seconds (134.127 MB/sec).
* run end
 
* restore: server[CNDCDWSQL90]>>[CNSISTWSQL100], database[DB_CATA_EXT]>>[DB_CATA_EXT_ST2]

(2 rows affected)
* run sql:
restore database DB_CATA_EXT_ST2
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\CNDCDWSQL90_DB_CATA_EXT_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'DB_CATA_EXT_Data' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_CATA_EXT_ST2.mdf',
     move 'DB_CATA_EXT_Log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_CATA_EXT_ST2_log.ldf',
     file = 1,
     medianame = 'CNDCDWSQL90_DB_CATA_EXT_full_backup_2025_04_09_16_02_28',
     stats = 1;
1 percent processed.
2 percent processed.
3 percent processed.
4 percent processed.
5 percent processed.
6 percent processed.
7 percent processed.
8 percent processed.
9 percent processed.
10 percent processed.
11 percent processed.
12 percent processed.
13 percent processed.
14 percent processed.
15 percent processed.
16 percent processed.
17 percent processed.
18 percent processed.
19 percent processed.
20 percent processed.
21 percent processed.
22 percent processed.
23 percent processed.
24 percent processed.
25 percent processed.
26 percent processed.
27 percent processed.
28 percent processed.
29 percent processed.
30 percent processed.
31 percent processed.
32 percent processed.
33 percent processed.
34 percent processed.
35 percent processed.
36 percent processed.
37 percent processed.
38 percent processed.
39 percent processed.
40 percent processed.
41 percent processed.
42 percent processed.
43 percent processed.
44 percent processed.
45 percent processed.
46 percent processed.
47 percent processed.
48 percent processed.
49 percent processed.
50 percent processed.
51 percent processed.
52 percent processed.
53 percent processed.
54 percent processed.
55 percent processed.
56 percent processed.
57 percent processed.
58 percent processed.
59 percent processed.
60 percent processed.
61 percent processed.
62 percent processed.
63 percent processed.
64 percent processed.
65 percent processed.
66 percent processed.
67 percent processed.
68 percent processed.
69 percent processed.
70 percent processed.
71 percent processed.
72 percent processed.
73 percent processed.
74 percent processed.
75 percent processed.
76 percent processed.
77 percent processed.
78 percent processed.
79 percent processed.
80 percent processed.
81 percent processed.
82 percent processed.
83 percent processed.
84 percent processed.
85 percent processed.
86 percent processed.
87 percent processed.
88 percent processed.
89 percent processed.
90 percent processed.
91 percent processed.
92 percent processed.
93 percent processed.
94 percent processed.
95 percent processed.
96 percent processed.
97 percent processed.
98 percent processed.
99 percent processed.
100 percent processed.
Processed 200608 pages for database 'DB_CATA_EXT_ST2', file 'DB_CATA_EXT_Data' on file 1.
Processed 1 pages for database 'DB_CATA_EXT_ST2', file 'DB_CATA_EXT_Log' on file 1.
Converting database 'DB_CATA_EXT_ST2' from version 904 to the current version 957.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 904 to version 905.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 905 to version 906.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 906 to version 907.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 907 to version 908.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 908 to version 909.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 909 to version 910.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 910 to version 911.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 911 to version 912.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 912 to version 913.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 913 to version 914.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 914 to version 915.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 915 to version 916.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 916 to version 917.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 917 to version 918.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 918 to version 919.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 919 to version 920.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 920 to version 921.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 921 to version 922.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 922 to version 923.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 923 to version 924.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 924 to version 925.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 925 to version 926.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 926 to version 927.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 927 to version 928.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 928 to version 929.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 929 to version 930.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 930 to version 931.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 931 to version 932.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 932 to version 933.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 933 to version 934.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 934 to version 935.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 935 to version 936.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 936 to version 937.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 937 to version 938.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 938 to version 939.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 939 to version 940.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 940 to version 941.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 941 to version 942.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 942 to version 943.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 943 to version 944.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 944 to version 945.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 945 to version 946.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 946 to version 947.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 947 to version 948.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 948 to version 949.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 949 to version 950.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 950 to version 951.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 951 to version 952.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 952 to version 953.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 953 to version 954.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 954 to version 955.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 955 to version 956.
Database 'DB_CATA_EXT_ST2' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 200609 pages in 19.680 seconds (79.636 MB/sec).
* run end
 
* restore: server[CNDCDWSQL90]>>[CNSISTWSQL100], database[DB_DC1]>>[DB_DC1_ST2]

(2 rows affected)
* run sql:
restore database DB_DC1_ST2
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\CNDCDWSQL90_DB_DC1_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'DB_DC1_Data' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_DC1_ST2.mdf',
     move 'DB_DC1_log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_DC1_ST2_log.ldf',
     file = 1,
     medianame = 'CNDCDWSQL90_DB_DC1_full_backup_2025_04_09_16_02_28',
     stats = 1;
1 percent processed.
2 percent processed.
3 percent processed.
4 percent processed.
5 percent processed.
6 percent processed.
7 percent processed.
8 percent processed.
9 percent processed.
10 percent processed.
11 percent processed.
12 percent processed.
13 percent processed.
14 percent processed.
15 percent processed.
16 percent processed.
17 percent processed.
18 percent processed.
19 percent processed.
20 percent processed.
21 percent processed.
22 percent processed.
23 percent processed.
24 percent processed.
25 percent processed.
26 percent processed.
27 percent processed.
28 percent processed.
29 percent processed.
30 percent processed.
31 percent processed.
32 percent processed.
33 percent processed.
34 percent processed.
35 percent processed.
36 percent processed.
37 percent processed.
38 percent processed.
39 percent processed.
40 percent processed.
41 percent processed.
42 percent processed.
43 percent processed.
44 percent processed.
45 percent processed.
46 percent processed.
47 percent processed.
48 percent processed.
49 percent processed.
50 percent processed.
51 percent processed.
52 percent processed.
53 percent processed.
54 percent processed.
55 percent processed.
56 percent processed.
57 percent processed.
58 percent processed.
59 percent processed.
60 percent processed.
61 percent processed.
62 percent processed.
63 percent processed.
64 percent processed.
65 percent processed.
66 percent processed.
67 percent processed.
68 percent processed.
69 percent processed.
70 percent processed.
71 percent processed.
72 percent processed.
73 percent processed.
74 percent processed.
75 percent processed.
76 percent processed.
77 percent processed.
78 percent processed.
79 percent processed.
80 percent processed.
81 percent processed.
82 percent processed.
83 percent processed.
84 percent processed.
85 percent processed.
86 percent processed.
87 percent processed.
88 percent processed.
89 percent processed.
90 percent processed.
91 percent processed.
92 percent processed.
93 percent processed.
94 percent processed.
95 percent processed.
96 percent processed.
97 percent processed.
98 percent processed.
99 percent processed.
100 percent processed.
Processed 98872 pages for database 'DB_DC1_ST2', file 'DB_DC1_Data' on file 1.
Processed 1 pages for database 'DB_DC1_ST2', file 'DB_DC1_log' on file 1.
Converting database 'DB_DC1_ST2' from version 904 to the current version 957.
Database 'DB_DC1_ST2' running the upgrade step from version 904 to version 905.
Database 'DB_DC1_ST2' running the upgrade step from version 905 to version 906.
Database 'DB_DC1_ST2' running the upgrade step from version 906 to version 907.
Database 'DB_DC1_ST2' running the upgrade step from version 907 to version 908.
Database 'DB_DC1_ST2' running the upgrade step from version 908 to version 909.
Database 'DB_DC1_ST2' running the upgrade step from version 909 to version 910.
Database 'DB_DC1_ST2' running the upgrade step from version 910 to version 911.
Database 'DB_DC1_ST2' running the upgrade step from version 911 to version 912.
Database 'DB_DC1_ST2' running the upgrade step from version 912 to version 913.
Database 'DB_DC1_ST2' running the upgrade step from version 913 to version 914.
Database 'DB_DC1_ST2' running the upgrade step from version 914 to version 915.
Database 'DB_DC1_ST2' running the upgrade step from version 915 to version 916.
Database 'DB_DC1_ST2' running the upgrade step from version 916 to version 917.
Database 'DB_DC1_ST2' running the upgrade step from version 917 to version 918.
Database 'DB_DC1_ST2' running the upgrade step from version 918 to version 919.
Database 'DB_DC1_ST2' running the upgrade step from version 919 to version 920.
Database 'DB_DC1_ST2' running the upgrade step from version 920 to version 921.
Database 'DB_DC1_ST2' running the upgrade step from version 921 to version 922.
Database 'DB_DC1_ST2' running the upgrade step from version 922 to version 923.
Database 'DB_DC1_ST2' running the upgrade step from version 923 to version 924.
Database 'DB_DC1_ST2' running the upgrade step from version 924 to version 925.
Database 'DB_DC1_ST2' running the upgrade step from version 925 to version 926.
Database 'DB_DC1_ST2' running the upgrade step from version 926 to version 927.
Database 'DB_DC1_ST2' running the upgrade step from version 927 to version 928.
Database 'DB_DC1_ST2' running the upgrade step from version 928 to version 929.
Database 'DB_DC1_ST2' running the upgrade step from version 929 to version 930.
Database 'DB_DC1_ST2' running the upgrade step from version 930 to version 931.
Database 'DB_DC1_ST2' running the upgrade step from version 931 to version 932.
Database 'DB_DC1_ST2' running the upgrade step from version 932 to version 933.
Database 'DB_DC1_ST2' running the upgrade step from version 933 to version 934.
Database 'DB_DC1_ST2' running the upgrade step from version 934 to version 935.
Database 'DB_DC1_ST2' running the upgrade step from version 935 to version 936.
Database 'DB_DC1_ST2' running the upgrade step from version 936 to version 937.
Database 'DB_DC1_ST2' running the upgrade step from version 937 to version 938.
Database 'DB_DC1_ST2' running the upgrade step from version 938 to version 939.
Database 'DB_DC1_ST2' running the upgrade step from version 939 to version 940.
Database 'DB_DC1_ST2' running the upgrade step from version 940 to version 941.
Database 'DB_DC1_ST2' running the upgrade step from version 941 to version 942.
Database 'DB_DC1_ST2' running the upgrade step from version 942 to version 943.
Database 'DB_DC1_ST2' running the upgrade step from version 943 to version 944.
Database 'DB_DC1_ST2' running the upgrade step from version 944 to version 945.
Database 'DB_DC1_ST2' running the upgrade step from version 945 to version 946.
Database 'DB_DC1_ST2' running the upgrade step from version 946 to version 947.
Database 'DB_DC1_ST2' running the upgrade step from version 947 to version 948.
Database 'DB_DC1_ST2' running the upgrade step from version 948 to version 949.
Database 'DB_DC1_ST2' running the upgrade step from version 949 to version 950.
Database 'DB_DC1_ST2' running the upgrade step from version 950 to version 951.
Database 'DB_DC1_ST2' running the upgrade step from version 951 to version 952.
Database 'DB_DC1_ST2' running the upgrade step from version 952 to version 953.
Database 'DB_DC1_ST2' running the upgrade step from version 953 to version 954.
Database 'DB_DC1_ST2' running the upgrade step from version 954 to version 955.
Database 'DB_DC1_ST2' running the upgrade step from version 955 to version 956.
Database 'DB_DC1_ST2' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 98873 pages in 4.967 seconds (155.514 MB/sec).
* run end
 
* restore: server[CNDCDWSQL90]>>[CNSISTWSQL100], database[DB_IWS_GNL]>>[DB_IWS_GNL_ST2]

(2 rows affected)
* run sql:
restore database DB_IWS_GNL_ST2
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\CNDCDWSQL90_DB_IWS_GNL_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'DB_IWS_GNL_Data' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_IWS_GNL_ST2.mdf',
     move 'DB_IWS_GNL_Log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_IWS_GNL_ST2_log.ldf',
     file = 1,
     medianame = 'CNDCDWSQL90_DB_IWS_GNL_full_backup_2025_04_09_16_02_28',
     stats = 1;
1 percent processed.
2 percent processed.
3 percent processed.
4 percent processed.
5 percent processed.
6 percent processed.
7 percent processed.
8 percent processed.
9 percent processed.
10 percent processed.
11 percent processed.
12 percent processed.
13 percent processed.
14 percent processed.
15 percent processed.
16 percent processed.
17 percent processed.
18 percent processed.
19 percent processed.
20 percent processed.
21 percent processed.
22 percent processed.
23 percent processed.
24 percent processed.
25 percent processed.
26 percent processed.
27 percent processed.
28 percent processed.
29 percent processed.
30 percent processed.
31 percent processed.
32 percent processed.
33 percent processed.
34 percent processed.
35 percent processed.
36 percent processed.
37 percent processed.
38 percent processed.
39 percent processed.
40 percent processed.
41 percent processed.
42 percent processed.
43 percent processed.
44 percent processed.
45 percent processed.
46 percent processed.
47 percent processed.
48 percent processed.
49 percent processed.
50 percent processed.
51 percent processed.
52 percent processed.
53 percent processed.
54 percent processed.
55 percent processed.
56 percent processed.
57 percent processed.
58 percent processed.
59 percent processed.
60 percent processed.
61 percent processed.
62 percent processed.
63 percent processed.
64 percent processed.
65 percent processed.
66 percent processed.
67 percent processed.
68 percent processed.
69 percent processed.
70 percent processed.
71 percent processed.
72 percent processed.
73 percent processed.
74 percent processed.
75 percent processed.
76 percent processed.
77 percent processed.
78 percent processed.
79 percent processed.
80 percent processed.
81 percent processed.
82 percent processed.
83 percent processed.
84 percent processed.
85 percent processed.
86 percent processed.
87 percent processed.
88 percent processed.
89 percent processed.
90 percent processed.
91 percent processed.
92 percent processed.
93 percent processed.
94 percent processed.
95 percent processed.
96 percent processed.
97 percent processed.
98 percent processed.
99 percent processed.
100 percent processed.
Processed 27512 pages for database 'DB_IWS_GNL_ST2', file 'DB_IWS_GNL_Data' on file 1.
Processed 1 pages for database 'DB_IWS_GNL_ST2', file 'DB_IWS_GNL_Log' on file 1.
Converting database 'DB_IWS_GNL_ST2' from version 904 to the current version 957.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 904 to version 905.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 905 to version 906.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 906 to version 907.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 907 to version 908.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 908 to version 909.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 909 to version 910.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 910 to version 911.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 911 to version 912.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 912 to version 913.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 913 to version 914.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 914 to version 915.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 915 to version 916.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 916 to version 917.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 917 to version 918.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 918 to version 919.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 919 to version 920.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 920 to version 921.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 921 to version 922.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 922 to version 923.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 923 to version 924.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 924 to version 925.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 925 to version 926.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 926 to version 927.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 927 to version 928.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 928 to version 929.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 929 to version 930.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 930 to version 931.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 931 to version 932.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 932 to version 933.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 933 to version 934.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 934 to version 935.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 935 to version 936.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 936 to version 937.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 937 to version 938.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 938 to version 939.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 939 to version 940.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 940 to version 941.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 941 to version 942.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 942 to version 943.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 943 to version 944.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 944 to version 945.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 945 to version 946.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 946 to version 947.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 947 to version 948.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 948 to version 949.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 949 to version 950.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 950 to version 951.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 951 to version 952.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 952 to version 953.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 953 to version 954.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 954 to version 955.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 955 to version 956.
Database 'DB_IWS_GNL_ST2' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 27513 pages in 2.029 seconds (105.933 MB/sec).
* run end
 
* restore: server[CNDCDWSQL90]>>[CNSISTWSQL100], database[DB_IWS_SCAN]>>[DB_IWS_SCAN_ST2]

(2 rows affected)
* run sql:
restore database DB_IWS_SCAN_ST2
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\CNDCDWSQL90_DB_IWS_SCAN_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'DB_IWS_SCAN' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_IWS_SCAN_ST2.mdf',
     move 'DB_IWS_SCAN_log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_IWS_SCAN_ST2_log.ldf',
     file = 1,
     medianame = 'CNDCDWSQL90_DB_IWS_SCAN_full_backup_2025_04_09_16_02_28',
     stats = 1;
1 percent processed.
2 percent processed.
3 percent processed.
4 percent processed.
5 percent processed.
6 percent processed.
7 percent processed.
8 percent processed.
9 percent processed.
10 percent processed.
11 percent processed.
12 percent processed.
13 percent processed.
14 percent processed.
15 percent processed.
16 percent processed.
17 percent processed.
18 percent processed.
19 percent processed.
20 percent processed.
21 percent processed.
22 percent processed.
23 percent processed.
24 percent processed.
25 percent processed.
26 percent processed.
27 percent processed.
28 percent processed.
29 percent processed.
30 percent processed.
31 percent processed.
32 percent processed.
33 percent processed.
34 percent processed.
35 percent processed.
36 percent processed.
37 percent processed.
38 percent processed.
39 percent processed.
40 percent processed.
41 percent processed.
42 percent processed.
43 percent processed.
44 percent processed.
45 percent processed.
46 percent processed.
47 percent processed.
48 percent processed.
49 percent processed.
50 percent processed.
51 percent processed.
52 percent processed.
53 percent processed.
54 percent processed.
55 percent processed.
56 percent processed.
57 percent processed.
58 percent processed.
59 percent processed.
60 percent processed.
61 percent processed.
62 percent processed.
63 percent processed.
64 percent processed.
65 percent processed.
66 percent processed.
67 percent processed.
68 percent processed.
69 percent processed.
70 percent processed.
71 percent processed.
72 percent processed.
73 percent processed.
74 percent processed.
75 percent processed.
76 percent processed.
77 percent processed.
78 percent processed.
79 percent processed.
80 percent processed.
81 percent processed.
82 percent processed.
83 percent processed.
84 percent processed.
85 percent processed.
86 percent processed.
87 percent processed.
88 percent processed.
89 percent processed.
90 percent processed.
91 percent processed.
92 percent processed.
93 percent processed.
94 percent processed.
95 percent processed.
96 percent processed.
97 percent processed.
98 percent processed.
99 percent processed.
100 percent processed.
Processed 153048 pages for database 'DB_IWS_SCAN_ST2', file 'DB_IWS_SCAN' on file 1.
Processed 1 pages for database 'DB_IWS_SCAN_ST2', file 'DB_IWS_SCAN_log' on file 1.
Converting database 'DB_IWS_SCAN_ST2' from version 904 to the current version 957.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 904 to version 905.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 905 to version 906.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 906 to version 907.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 907 to version 908.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 908 to version 909.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 909 to version 910.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 910 to version 911.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 911 to version 912.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 912 to version 913.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 913 to version 914.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 914 to version 915.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 915 to version 916.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 916 to version 917.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 917 to version 918.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 918 to version 919.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 919 to version 920.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 920 to version 921.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 921 to version 922.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 922 to version 923.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 923 to version 924.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 924 to version 925.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 925 to version 926.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 926 to version 927.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 927 to version 928.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 928 to version 929.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 929 to version 930.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 930 to version 931.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 931 to version 932.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 932 to version 933.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 933 to version 934.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 934 to version 935.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 935 to version 936.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 936 to version 937.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 937 to version 938.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 938 to version 939.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 939 to version 940.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 940 to version 941.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 941 to version 942.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 942 to version 943.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 943 to version 944.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 944 to version 945.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 945 to version 946.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 946 to version 947.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 947 to version 948.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 948 to version 949.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 949 to version 950.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 950 to version 951.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 951 to version 952.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 952 to version 953.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 953 to version 954.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 954 to version 955.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 955 to version 956.
Database 'DB_IWS_SCAN_ST2' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 153049 pages in 5.993 seconds (199.514 MB/sec).
* run end
 
* restore: server[CNDCDWSQL90]>>[CNSISTWSQL100], database[DB_SIGN]>>[DB_SIGN_ST2]

(2 rows affected)
* run sql:
restore database DB_SIGN_ST2
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\CNDCDWSQL90_DB_SIGN_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'DB_SIGN_Data' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_SIGN_ST2.mdf',
     move 'DB_SIGN_Log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_SIGN_ST2_log.ldf',
     file = 1,
     medianame = 'CNDCDWSQL90_DB_SIGN_full_backup_2025_04_09_16_02_28',
     stats = 1;
1 percent processed.
2 percent processed.
3 percent processed.
4 percent processed.
5 percent processed.
6 percent processed.
7 percent processed.
8 percent processed.
9 percent processed.
10 percent processed.
11 percent processed.
12 percent processed.
13 percent processed.
14 percent processed.
15 percent processed.
16 percent processed.
17 percent processed.
18 percent processed.
19 percent processed.
20 percent processed.
21 percent processed.
22 percent processed.
23 percent processed.
24 percent processed.
25 percent processed.
26 percent processed.
27 percent processed.
28 percent processed.
29 percent processed.
30 percent processed.
31 percent processed.
32 percent processed.
33 percent processed.
34 percent processed.
35 percent processed.
36 percent processed.
37 percent processed.
38 percent processed.
39 percent processed.
40 percent processed.
41 percent processed.
42 percent processed.
43 percent processed.
44 percent processed.
45 percent processed.
46 percent processed.
47 percent processed.
48 percent processed.
49 percent processed.
50 percent processed.
51 percent processed.
52 percent processed.
53 percent processed.
54 percent processed.
55 percent processed.
56 percent processed.
57 percent processed.
58 percent processed.
59 percent processed.
60 percent processed.
61 percent processed.
62 percent processed.
63 percent processed.
64 percent processed.
65 percent processed.
66 percent processed.
67 percent processed.
68 percent processed.
69 percent processed.
70 percent processed.
71 percent processed.
72 percent processed.
73 percent processed.
74 percent processed.
75 percent processed.
76 percent processed.
77 percent processed.
78 percent processed.
79 percent processed.
80 percent processed.
81 percent processed.
82 percent processed.
83 percent processed.
84 percent processed.
85 percent processed.
86 percent processed.
87 percent processed.
88 percent processed.
89 percent processed.
90 percent processed.
91 percent processed.
92 percent processed.
93 percent processed.
94 percent processed.
95 percent processed.
96 percent processed.
97 percent processed.
98 percent processed.
99 percent processed.
100 percent processed.
Processed 13416 pages for database 'DB_SIGN_ST2', file 'DB_SIGN_Data' on file 1.
Processed 1 pages for database 'DB_SIGN_ST2', file 'DB_SIGN_Log' on file 1.
Converting database 'DB_SIGN_ST2' from version 904 to the current version 957.
Database 'DB_SIGN_ST2' running the upgrade step from version 904 to version 905.
Database 'DB_SIGN_ST2' running the upgrade step from version 905 to version 906.
Database 'DB_SIGN_ST2' running the upgrade step from version 906 to version 907.
Database 'DB_SIGN_ST2' running the upgrade step from version 907 to version 908.
Database 'DB_SIGN_ST2' running the upgrade step from version 908 to version 909.
Database 'DB_SIGN_ST2' running the upgrade step from version 909 to version 910.
Database 'DB_SIGN_ST2' running the upgrade step from version 910 to version 911.
Database 'DB_SIGN_ST2' running the upgrade step from version 911 to version 912.
Database 'DB_SIGN_ST2' running the upgrade step from version 912 to version 913.
Database 'DB_SIGN_ST2' running the upgrade step from version 913 to version 914.
Database 'DB_SIGN_ST2' running the upgrade step from version 914 to version 915.
Database 'DB_SIGN_ST2' running the upgrade step from version 915 to version 916.
Database 'DB_SIGN_ST2' running the upgrade step from version 916 to version 917.
Database 'DB_SIGN_ST2' running the upgrade step from version 917 to version 918.
Database 'DB_SIGN_ST2' running the upgrade step from version 918 to version 919.
Database 'DB_SIGN_ST2' running the upgrade step from version 919 to version 920.
Database 'DB_SIGN_ST2' running the upgrade step from version 920 to version 921.
Database 'DB_SIGN_ST2' running the upgrade step from version 921 to version 922.
Database 'DB_SIGN_ST2' running the upgrade step from version 922 to version 923.
Database 'DB_SIGN_ST2' running the upgrade step from version 923 to version 924.
Database 'DB_SIGN_ST2' running the upgrade step from version 924 to version 925.
Database 'DB_SIGN_ST2' running the upgrade step from version 925 to version 926.
Database 'DB_SIGN_ST2' running the upgrade step from version 926 to version 927.
Database 'DB_SIGN_ST2' running the upgrade step from version 927 to version 928.
Database 'DB_SIGN_ST2' running the upgrade step from version 928 to version 929.
Database 'DB_SIGN_ST2' running the upgrade step from version 929 to version 930.
Database 'DB_SIGN_ST2' running the upgrade step from version 930 to version 931.
Database 'DB_SIGN_ST2' running the upgrade step from version 931 to version 932.
Database 'DB_SIGN_ST2' running the upgrade step from version 932 to version 933.
Database 'DB_SIGN_ST2' running the upgrade step from version 933 to version 934.
Database 'DB_SIGN_ST2' running the upgrade step from version 934 to version 935.
Database 'DB_SIGN_ST2' running the upgrade step from version 935 to version 936.
Database 'DB_SIGN_ST2' running the upgrade step from version 936 to version 937.
Database 'DB_SIGN_ST2' running the upgrade step from version 937 to version 938.
Database 'DB_SIGN_ST2' running the upgrade step from version 938 to version 939.
Database 'DB_SIGN_ST2' running the upgrade step from version 939 to version 940.
Database 'DB_SIGN_ST2' running the upgrade step from version 940 to version 941.
Database 'DB_SIGN_ST2' running the upgrade step from version 941 to version 942.
Database 'DB_SIGN_ST2' running the upgrade step from version 942 to version 943.
Database 'DB_SIGN_ST2' running the upgrade step from version 943 to version 944.
Database 'DB_SIGN_ST2' running the upgrade step from version 944 to version 945.
Database 'DB_SIGN_ST2' running the upgrade step from version 945 to version 946.
Database 'DB_SIGN_ST2' running the upgrade step from version 946 to version 947.
Database 'DB_SIGN_ST2' running the upgrade step from version 947 to version 948.
Database 'DB_SIGN_ST2' running the upgrade step from version 948 to version 949.
Database 'DB_SIGN_ST2' running the upgrade step from version 949 to version 950.
Database 'DB_SIGN_ST2' running the upgrade step from version 950 to version 951.
Database 'DB_SIGN_ST2' running the upgrade step from version 951 to version 952.
Database 'DB_SIGN_ST2' running the upgrade step from version 952 to version 953.
Database 'DB_SIGN_ST2' running the upgrade step from version 953 to version 954.
Database 'DB_SIGN_ST2' running the upgrade step from version 954 to version 955.
Database 'DB_SIGN_ST2' running the upgrade step from version 955 to version 956.
Database 'DB_SIGN_ST2' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 13417 pages in 0.539 seconds (194.460 MB/sec).
* run end
 
* restore: server[CNSISTWSQL050]>>[CNSISTWSQL100], database[KAMI]>>[KAMI]

(2 rows affected)
* run sql:
restore database KAMI
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\CNSISTWSQL050_KAMI_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'Kami' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\KAMI.mdf',
     move 'Kami_log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\KAMI_log.ldf',
     file = 1,
     medianame = 'CNSISTWSQL050_KAMI_full_backup_2025_04_09_16_02_28',
     stats = 1;
1 percent processed.
2 percent processed.
3 percent processed.
4 percent processed.
5 percent processed.
6 percent processed.
7 percent processed.
8 percent processed.
9 percent processed.
10 percent processed.
11 percent processed.
12 percent processed.
13 percent processed.
14 percent processed.
15 percent processed.
16 percent processed.
17 percent processed.
18 percent processed.
19 percent processed.
20 percent processed.
21 percent processed.
22 percent processed.
23 percent processed.
24 percent processed.
25 percent processed.
26 percent processed.
27 percent processed.
28 percent processed.
29 percent processed.
30 percent processed.
31 percent processed.
32 percent processed.
33 percent processed.
34 percent processed.
35 percent processed.
36 percent processed.
37 percent processed.
38 percent processed.
39 percent processed.
40 percent processed.
41 percent processed.
42 percent processed.
43 percent processed.
44 percent processed.
45 percent processed.
46 percent processed.
47 percent processed.
48 percent processed.
49 percent processed.
50 percent processed.
51 percent processed.
52 percent processed.
53 percent processed.
54 percent processed.
55 percent processed.
56 percent processed.
57 percent processed.
58 percent processed.
59 percent processed.
60 percent processed.
61 percent processed.
62 percent processed.
63 percent processed.
64 percent processed.
65 percent processed.
66 percent processed.
67 percent processed.
68 percent processed.
69 percent processed.
70 percent processed.
71 percent processed.
72 percent processed.
73 percent processed.
74 percent processed.
75 percent processed.
76 percent processed.
77 percent processed.
78 percent processed.
79 percent processed.
80 percent processed.
81 percent processed.
82 percent processed.
83 percent processed.
84 percent processed.
85 percent processed.
86 percent processed.
87 percent processed.
88 percent processed.
89 percent processed.
90 percent processed.
91 percent processed.
92 percent processed.
93 percent processed.
94 percent processed.
95 percent processed.
96 percent processed.
97 percent processed.
98 percent processed.
99 percent processed.
100 percent processed.
Processed 337304 pages for database 'KAMI', file 'Kami' on file 1.
Processed 1 pages for database 'KAMI', file 'Kami_log' on file 1.
Converting database 'KAMI' from version 904 to the current version 957.
Database 'KAMI' running the upgrade step from version 904 to version 905.
Database 'KAMI' running the upgrade step from version 905 to version 906.
Database 'KAMI' running the upgrade step from version 906 to version 907.
Database 'KAMI' running the upgrade step from version 907 to version 908.
Database 'KAMI' running the upgrade step from version 908 to version 909.
Database 'KAMI' running the upgrade step from version 909 to version 910.
Database 'KAMI' running the upgrade step from version 910 to version 911.
Database 'KAMI' running the upgrade step from version 911 to version 912.
Database 'KAMI' running the upgrade step from version 912 to version 913.
Database 'KAMI' running the upgrade step from version 913 to version 914.
Database 'KAMI' running the upgrade step from version 914 to version 915.
Database 'KAMI' running the upgrade step from version 915 to version 916.
Database 'KAMI' running the upgrade step from version 916 to version 917.
Database 'KAMI' running the upgrade step from version 917 to version 918.
Database 'KAMI' running the upgrade step from version 918 to version 919.
Database 'KAMI' running the upgrade step from version 919 to version 920.
Database 'KAMI' running the upgrade step from version 920 to version 921.
Database 'KAMI' running the upgrade step from version 921 to version 922.
Database 'KAMI' running the upgrade step from version 922 to version 923.
Database 'KAMI' running the upgrade step from version 923 to version 924.
Database 'KAMI' running the upgrade step from version 924 to version 925.
Database 'KAMI' running the upgrade step from version 925 to version 926.
Database 'KAMI' running the upgrade step from version 926 to version 927.
Database 'KAMI' running the upgrade step from version 927 to version 928.
Database 'KAMI' running the upgrade step from version 928 to version 929.
Database 'KAMI' running the upgrade step from version 929 to version 930.
Database 'KAMI' running the upgrade step from version 930 to version 931.
Database 'KAMI' running the upgrade step from version 931 to version 932.
Database 'KAMI' running the upgrade step from version 932 to version 933.
Database 'KAMI' running the upgrade step from version 933 to version 934.
Database 'KAMI' running the upgrade step from version 934 to version 935.
Database 'KAMI' running the upgrade step from version 935 to version 936.
Database 'KAMI' running the upgrade step from version 936 to version 937.
Database 'KAMI' running the upgrade step from version 937 to version 938.
Database 'KAMI' running the upgrade step from version 938 to version 939.
Database 'KAMI' running the upgrade step from version 939 to version 940.
Database 'KAMI' running the upgrade step from version 940 to version 941.
Database 'KAMI' running the upgrade step from version 941 to version 942.
Database 'KAMI' running the upgrade step from version 942 to version 943.
Database 'KAMI' running the upgrade step from version 943 to version 944.
Database 'KAMI' running the upgrade step from version 944 to version 945.
Database 'KAMI' running the upgrade step from version 945 to version 946.
Database 'KAMI' running the upgrade step from version 946 to version 947.
Database 'KAMI' running the upgrade step from version 947 to version 948.
Database 'KAMI' running the upgrade step from version 948 to version 949.
Database 'KAMI' running the upgrade step from version 949 to version 950.
Database 'KAMI' running the upgrade step from version 950 to version 951.
Database 'KAMI' running the upgrade step from version 951 to version 952.
Database 'KAMI' running the upgrade step from version 952 to version 953.
Database 'KAMI' running the upgrade step from version 953 to version 954.
Database 'KAMI' running the upgrade step from version 954 to version 955.
Database 'KAMI' running the upgrade step from version 955 to version 956.
Database 'KAMI' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 337305 pages in 15.580 seconds (169.139 MB/sec).
* run end
 
* restore: server[cnsistwsql070]>>[CNSISTWSQL100], database[DB_CATA_EXT_ST3]>>[DB_CATA_EXT_ST3]

(2 rows affected)
* run sql:
restore database DB_CATA_EXT_ST3
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\cnsistwsql070_DB_CATA_EXT_ST3_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'DB_CATA_EXT_Data' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_CATA_EXT_ST3.mdf',
     move 'DB_CATA_EXT_Log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_CATA_EXT_ST3_log.ldf',
     file = 1,
     medianame = 'cnsistwsql070_DB_CATA_EXT_ST3_full_backup_2025_04_09_16_02_28',
     stats = 1;
1 percent processed.
2 percent processed.
3 percent processed.
4 percent processed.
5 percent processed.
6 percent processed.
7 percent processed.
8 percent processed.
9 percent processed.
10 percent processed.
11 percent processed.
12 percent processed.
13 percent processed.
14 percent processed.
15 percent processed.
16 percent processed.
17 percent processed.
18 percent processed.
19 percent processed.
20 percent processed.
21 percent processed.
22 percent processed.
23 percent processed.
24 percent processed.
25 percent processed.
26 percent processed.
27 percent processed.
28 percent processed.
29 percent processed.
30 percent processed.
31 percent processed.
32 percent processed.
33 percent processed.
34 percent processed.
35 percent processed.
36 percent processed.
37 percent processed.
38 percent processed.
39 percent processed.
40 percent processed.
41 percent processed.
42 percent processed.
43 percent processed.
44 percent processed.
45 percent processed.
46 percent processed.
47 percent processed.
48 percent processed.
49 percent processed.
50 percent processed.
51 percent processed.
52 percent processed.
53 percent processed.
54 percent processed.
55 percent processed.
56 percent processed.
57 percent processed.
58 percent processed.
59 percent processed.
60 percent processed.
61 percent processed.
62 percent processed.
63 percent processed.
64 percent processed.
65 percent processed.
66 percent processed.
67 percent processed.
68 percent processed.
69 percent processed.
70 percent processed.
71 percent processed.
72 percent processed.
73 percent processed.
74 percent processed.
75 percent processed.
76 percent processed.
77 percent processed.
78 percent processed.
79 percent processed.
80 percent processed.
81 percent processed.
82 percent processed.
83 percent processed.
84 percent processed.
85 percent processed.
86 percent processed.
87 percent processed.
88 percent processed.
89 percent processed.
90 percent processed.
91 percent processed.
92 percent processed.
93 percent processed.
94 percent processed.
95 percent processed.
96 percent processed.
97 percent processed.
98 percent processed.
99 percent processed.
100 percent processed.
Processed 16136 pages for database 'DB_CATA_EXT_ST3', file 'DB_CATA_EXT_Data' on file 1.
Processed 1 pages for database 'DB_CATA_EXT_ST3', file 'DB_CATA_EXT_Log' on file 1.
Converting database 'DB_CATA_EXT_ST3' from version 904 to the current version 957.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 904 to version 905.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 905 to version 906.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 906 to version 907.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 907 to version 908.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 908 to version 909.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 909 to version 910.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 910 to version 911.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 911 to version 912.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 912 to version 913.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 913 to version 914.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 914 to version 915.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 915 to version 916.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 916 to version 917.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 917 to version 918.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 918 to version 919.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 919 to version 920.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 920 to version 921.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 921 to version 922.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 922 to version 923.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 923 to version 924.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 924 to version 925.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 925 to version 926.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 926 to version 927.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 927 to version 928.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 928 to version 929.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 929 to version 930.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 930 to version 931.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 931 to version 932.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 932 to version 933.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 933 to version 934.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 934 to version 935.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 935 to version 936.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 936 to version 937.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 937 to version 938.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 938 to version 939.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 939 to version 940.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 940 to version 941.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 941 to version 942.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 942 to version 943.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 943 to version 944.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 944 to version 945.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 945 to version 946.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 946 to version 947.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 947 to version 948.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 948 to version 949.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 949 to version 950.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 950 to version 951.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 951 to version 952.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 952 to version 953.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 953 to version 954.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 954 to version 955.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 955 to version 956.
Database 'DB_CATA_EXT_ST3' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 16137 pages in 0.909 seconds (138.684 MB/sec).
* run end
 
* restore: server[cnsistwsql070]>>[CNSISTWSQL100], database[DB_CATA_ST3]>>[DB_CATA_ST3]

(2 rows affected)
* run sql:
restore database DB_CATA_ST3
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\cnsistwsql070_DB_CATA_ST3_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'DB_CATA_Data' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_CATA_ST3.mdf',
     move 'DB_CATA_log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_CATA_ST3_log.ldf',
     file = 1,
     medianame = 'cnsistwsql070_DB_CATA_ST3_full_backup_2025_04_09_16_02_28',
     stats = 1;
6 percent processed.
13 percent processed.
19 percent processed.
26 percent processed.
32 percent processed.
39 percent processed.
46 percent processed.
52 percent processed.
59 percent processed.
65 percent processed.
72 percent processed.
78 percent processed.
85 percent processed.
92 percent processed.
98 percent processed.
100 percent processed.
Processed 1960 pages for database 'DB_CATA_ST3', file 'DB_CATA_Data' on file 1.
Processed 1 pages for database 'DB_CATA_ST3', file 'DB_CATA_log' on file 1.
Converting database 'DB_CATA_ST3' from version 904 to the current version 957.
Database 'DB_CATA_ST3' running the upgrade step from version 904 to version 905.
Database 'DB_CATA_ST3' running the upgrade step from version 905 to version 906.
Database 'DB_CATA_ST3' running the upgrade step from version 906 to version 907.
Database 'DB_CATA_ST3' running the upgrade step from version 907 to version 908.
Database 'DB_CATA_ST3' running the upgrade step from version 908 to version 909.
Database 'DB_CATA_ST3' running the upgrade step from version 909 to version 910.
Database 'DB_CATA_ST3' running the upgrade step from version 910 to version 911.
Database 'DB_CATA_ST3' running the upgrade step from version 911 to version 912.
Database 'DB_CATA_ST3' running the upgrade step from version 912 to version 913.
Database 'DB_CATA_ST3' running the upgrade step from version 913 to version 914.
Database 'DB_CATA_ST3' running the upgrade step from version 914 to version 915.
Database 'DB_CATA_ST3' running the upgrade step from version 915 to version 916.
Database 'DB_CATA_ST3' running the upgrade step from version 916 to version 917.
Database 'DB_CATA_ST3' running the upgrade step from version 917 to version 918.
Database 'DB_CATA_ST3' running the upgrade step from version 918 to version 919.
Database 'DB_CATA_ST3' running the upgrade step from version 919 to version 920.
Database 'DB_CATA_ST3' running the upgrade step from version 920 to version 921.
Database 'DB_CATA_ST3' running the upgrade step from version 921 to version 922.
Database 'DB_CATA_ST3' running the upgrade step from version 922 to version 923.
Database 'DB_CATA_ST3' running the upgrade step from version 923 to version 924.
Database 'DB_CATA_ST3' running the upgrade step from version 924 to version 925.
Database 'DB_CATA_ST3' running the upgrade step from version 925 to version 926.
Database 'DB_CATA_ST3' running the upgrade step from version 926 to version 927.
Database 'DB_CATA_ST3' running the upgrade step from version 927 to version 928.
Database 'DB_CATA_ST3' running the upgrade step from version 928 to version 929.
Database 'DB_CATA_ST3' running the upgrade step from version 929 to version 930.
Database 'DB_CATA_ST3' running the upgrade step from version 930 to version 931.
Database 'DB_CATA_ST3' running the upgrade step from version 931 to version 932.
Database 'DB_CATA_ST3' running the upgrade step from version 932 to version 933.
Database 'DB_CATA_ST3' running the upgrade step from version 933 to version 934.
Database 'DB_CATA_ST3' running the upgrade step from version 934 to version 935.
Database 'DB_CATA_ST3' running the upgrade step from version 935 to version 936.
Database 'DB_CATA_ST3' running the upgrade step from version 936 to version 937.
Database 'DB_CATA_ST3' running the upgrade step from version 937 to version 938.
Database 'DB_CATA_ST3' running the upgrade step from version 938 to version 939.
Database 'DB_CATA_ST3' running the upgrade step from version 939 to version 940.
Database 'DB_CATA_ST3' running the upgrade step from version 940 to version 941.
Database 'DB_CATA_ST3' running the upgrade step from version 941 to version 942.
Database 'DB_CATA_ST3' running the upgrade step from version 942 to version 943.
Database 'DB_CATA_ST3' running the upgrade step from version 943 to version 944.
Database 'DB_CATA_ST3' running the upgrade step from version 944 to version 945.
Database 'DB_CATA_ST3' running the upgrade step from version 945 to version 946.
Database 'DB_CATA_ST3' running the upgrade step from version 946 to version 947.
Database 'DB_CATA_ST3' running the upgrade step from version 947 to version 948.
Database 'DB_CATA_ST3' running the upgrade step from version 948 to version 949.
Database 'DB_CATA_ST3' running the upgrade step from version 949 to version 950.
Database 'DB_CATA_ST3' running the upgrade step from version 950 to version 951.
Database 'DB_CATA_ST3' running the upgrade step from version 951 to version 952.
Database 'DB_CATA_ST3' running the upgrade step from version 952 to version 953.
Database 'DB_CATA_ST3' running the upgrade step from version 953 to version 954.
Database 'DB_CATA_ST3' running the upgrade step from version 954 to version 955.
Database 'DB_CATA_ST3' running the upgrade step from version 955 to version 956.
Database 'DB_CATA_ST3' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 1961 pages in 0.161 seconds (95.117 MB/sec).
* run end
 
* restore: server[cnsistwsql070]>>[CNSISTWSQL100], database[DB_DC1_ST3]>>[DB_DC1_ST3]

(2 rows affected)
* run sql:
restore database DB_DC1_ST3
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\cnsistwsql070_DB_DC1_ST3_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'DB_DC1_Data' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_DC1_ST3.mdf',
     move 'DB_DC1_log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_DC1_ST3_log.ldf',
     file = 1,
     medianame = 'cnsistwsql070_DB_DC1_ST3_full_backup_2025_04_09_16_02_28',
     stats = 1;
1 percent processed.
2 percent processed.
3 percent processed.
4 percent processed.
5 percent processed.
6 percent processed.
7 percent processed.
8 percent processed.
9 percent processed.
10 percent processed.
11 percent processed.
12 percent processed.
13 percent processed.
14 percent processed.
15 percent processed.
16 percent processed.
17 percent processed.
18 percent processed.
19 percent processed.
20 percent processed.
21 percent processed.
22 percent processed.
23 percent processed.
24 percent processed.
25 percent processed.
26 percent processed.
27 percent processed.
28 percent processed.
29 percent processed.
30 percent processed.
31 percent processed.
32 percent processed.
33 percent processed.
34 percent processed.
35 percent processed.
36 percent processed.
37 percent processed.
38 percent processed.
39 percent processed.
40 percent processed.
41 percent processed.
42 percent processed.
43 percent processed.
44 percent processed.
45 percent processed.
46 percent processed.
47 percent processed.
48 percent processed.
49 percent processed.
50 percent processed.
51 percent processed.
52 percent processed.
53 percent processed.
54 percent processed.
55 percent processed.
56 percent processed.
57 percent processed.
58 percent processed.
59 percent processed.
60 percent processed.
61 percent processed.
62 percent processed.
63 percent processed.
64 percent processed.
65 percent processed.
66 percent processed.
67 percent processed.
68 percent processed.
69 percent processed.
70 percent processed.
71 percent processed.
72 percent processed.
73 percent processed.
74 percent processed.
75 percent processed.
76 percent processed.
77 percent processed.
78 percent processed.
79 percent processed.
80 percent processed.
81 percent processed.
82 percent processed.
83 percent processed.
84 percent processed.
85 percent processed.
86 percent processed.
87 percent processed.
88 percent processed.
89 percent processed.
90 percent processed.
91 percent processed.
92 percent processed.
93 percent processed.
94 percent processed.
95 percent processed.
96 percent processed.
97 percent processed.
98 percent processed.
99 percent processed.
100 percent processed.
Processed 188832 pages for database 'DB_DC1_ST3', file 'DB_DC1_Data' on file 1.
Processed 1 pages for database 'DB_DC1_ST3', file 'DB_DC1_log' on file 1.
Converting database 'DB_DC1_ST3' from version 904 to the current version 957.
Database 'DB_DC1_ST3' running the upgrade step from version 904 to version 905.
Database 'DB_DC1_ST3' running the upgrade step from version 905 to version 906.
Database 'DB_DC1_ST3' running the upgrade step from version 906 to version 907.
Database 'DB_DC1_ST3' running the upgrade step from version 907 to version 908.
Database 'DB_DC1_ST3' running the upgrade step from version 908 to version 909.
Database 'DB_DC1_ST3' running the upgrade step from version 909 to version 910.
Database 'DB_DC1_ST3' running the upgrade step from version 910 to version 911.
Database 'DB_DC1_ST3' running the upgrade step from version 911 to version 912.
Database 'DB_DC1_ST3' running the upgrade step from version 912 to version 913.
Database 'DB_DC1_ST3' running the upgrade step from version 913 to version 914.
Database 'DB_DC1_ST3' running the upgrade step from version 914 to version 915.
Database 'DB_DC1_ST3' running the upgrade step from version 915 to version 916.
Database 'DB_DC1_ST3' running the upgrade step from version 916 to version 917.
Database 'DB_DC1_ST3' running the upgrade step from version 917 to version 918.
Database 'DB_DC1_ST3' running the upgrade step from version 918 to version 919.
Database 'DB_DC1_ST3' running the upgrade step from version 919 to version 920.
Database 'DB_DC1_ST3' running the upgrade step from version 920 to version 921.
Database 'DB_DC1_ST3' running the upgrade step from version 921 to version 922.
Database 'DB_DC1_ST3' running the upgrade step from version 922 to version 923.
Database 'DB_DC1_ST3' running the upgrade step from version 923 to version 924.
Database 'DB_DC1_ST3' running the upgrade step from version 924 to version 925.
Database 'DB_DC1_ST3' running the upgrade step from version 925 to version 926.
Database 'DB_DC1_ST3' running the upgrade step from version 926 to version 927.
Database 'DB_DC1_ST3' running the upgrade step from version 927 to version 928.
Database 'DB_DC1_ST3' running the upgrade step from version 928 to version 929.
Database 'DB_DC1_ST3' running the upgrade step from version 929 to version 930.
Database 'DB_DC1_ST3' running the upgrade step from version 930 to version 931.
Database 'DB_DC1_ST3' running the upgrade step from version 931 to version 932.
Database 'DB_DC1_ST3' running the upgrade step from version 932 to version 933.
Database 'DB_DC1_ST3' running the upgrade step from version 933 to version 934.
Database 'DB_DC1_ST3' running the upgrade step from version 934 to version 935.
Database 'DB_DC1_ST3' running the upgrade step from version 935 to version 936.
Database 'DB_DC1_ST3' running the upgrade step from version 936 to version 937.
Database 'DB_DC1_ST3' running the upgrade step from version 937 to version 938.
Database 'DB_DC1_ST3' running the upgrade step from version 938 to version 939.
Database 'DB_DC1_ST3' running the upgrade step from version 939 to version 940.
Database 'DB_DC1_ST3' running the upgrade step from version 940 to version 941.
Database 'DB_DC1_ST3' running the upgrade step from version 941 to version 942.
Database 'DB_DC1_ST3' running the upgrade step from version 942 to version 943.
Database 'DB_DC1_ST3' running the upgrade step from version 943 to version 944.
Database 'DB_DC1_ST3' running the upgrade step from version 944 to version 945.
Database 'DB_DC1_ST3' running the upgrade step from version 945 to version 946.
Database 'DB_DC1_ST3' running the upgrade step from version 946 to version 947.
Database 'DB_DC1_ST3' running the upgrade step from version 947 to version 948.
Database 'DB_DC1_ST3' running the upgrade step from version 948 to version 949.
Database 'DB_DC1_ST3' running the upgrade step from version 949 to version 950.
Database 'DB_DC1_ST3' running the upgrade step from version 950 to version 951.
Database 'DB_DC1_ST3' running the upgrade step from version 951 to version 952.
Database 'DB_DC1_ST3' running the upgrade step from version 952 to version 953.
Database 'DB_DC1_ST3' running the upgrade step from version 953 to version 954.
Database 'DB_DC1_ST3' running the upgrade step from version 954 to version 955.
Database 'DB_DC1_ST3' running the upgrade step from version 955 to version 956.
Database 'DB_DC1_ST3' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 188833 pages in 8.348 seconds (176.719 MB/sec).
* run end
 
* restore: server[cnsistwsql070]>>[CNSISTWSQL100], database[DB_IWS_GNL_ST3]>>[DB_IWS_GNL_ST3]

(2 rows affected)
* run sql:
restore database DB_IWS_GNL_ST3
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\cnsistwsql070_DB_IWS_GNL_ST3_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'DB_IWS_GNL_Data' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_IWS_GNL_ST3.mdf',
     move 'DB_IWS_GNL_Log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_IWS_GNL_ST3_log.ldf',
     file = 1,
     medianame = 'cnsistwsql070_DB_IWS_GNL_ST3_full_backup_2025_04_09_16_02_28',
     stats = 1;
1 percent processed.
2 percent processed.
3 percent processed.
4 percent processed.
5 percent processed.
6 percent processed.
7 percent processed.
8 percent processed.
9 percent processed.
10 percent processed.
11 percent processed.
12 percent processed.
13 percent processed.
14 percent processed.
15 percent processed.
16 percent processed.
17 percent processed.
18 percent processed.
19 percent processed.
20 percent processed.
21 percent processed.
22 percent processed.
23 percent processed.
24 percent processed.
25 percent processed.
26 percent processed.
27 percent processed.
28 percent processed.
29 percent processed.
30 percent processed.
31 percent processed.
32 percent processed.
33 percent processed.
34 percent processed.
35 percent processed.
36 percent processed.
37 percent processed.
38 percent processed.
39 percent processed.
40 percent processed.
41 percent processed.
42 percent processed.
43 percent processed.
44 percent processed.
45 percent processed.
46 percent processed.
47 percent processed.
48 percent processed.
49 percent processed.
50 percent processed.
51 percent processed.
52 percent processed.
53 percent processed.
54 percent processed.
55 percent processed.
56 percent processed.
57 percent processed.
58 percent processed.
59 percent processed.
60 percent processed.
61 percent processed.
62 percent processed.
63 percent processed.
64 percent processed.
65 percent processed.
66 percent processed.
67 percent processed.
68 percent processed.
69 percent processed.
70 percent processed.
71 percent processed.
72 percent processed.
73 percent processed.
74 percent processed.
75 percent processed.
76 percent processed.
77 percent processed.
78 percent processed.
79 percent processed.
80 percent processed.
81 percent processed.
82 percent processed.
83 percent processed.
84 percent processed.
85 percent processed.
86 percent processed.
87 percent processed.
88 percent processed.
89 percent processed.
90 percent processed.
91 percent processed.
92 percent processed.
93 percent processed.
94 percent processed.
95 percent processed.
96 percent processed.
97 percent processed.
98 percent processed.
99 percent processed.
100 percent processed.
Processed 23160 pages for database 'DB_IWS_GNL_ST3', file 'DB_IWS_GNL_Data' on file 1.
Processed 1 pages for database 'DB_IWS_GNL_ST3', file 'DB_IWS_GNL_Log' on file 1.
Converting database 'DB_IWS_GNL_ST3' from version 904 to the current version 957.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 904 to version 905.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 905 to version 906.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 906 to version 907.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 907 to version 908.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 908 to version 909.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 909 to version 910.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 910 to version 911.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 911 to version 912.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 912 to version 913.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 913 to version 914.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 914 to version 915.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 915 to version 916.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 916 to version 917.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 917 to version 918.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 918 to version 919.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 919 to version 920.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 920 to version 921.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 921 to version 922.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 922 to version 923.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 923 to version 924.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 924 to version 925.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 925 to version 926.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 926 to version 927.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 927 to version 928.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 928 to version 929.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 929 to version 930.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 930 to version 931.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 931 to version 932.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 932 to version 933.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 933 to version 934.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 934 to version 935.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 935 to version 936.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 936 to version 937.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 937 to version 938.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 938 to version 939.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 939 to version 940.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 940 to version 941.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 941 to version 942.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 942 to version 943.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 943 to version 944.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 944 to version 945.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 945 to version 946.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 946 to version 947.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 947 to version 948.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 948 to version 949.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 949 to version 950.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 950 to version 951.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 951 to version 952.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 952 to version 953.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 953 to version 954.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 954 to version 955.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 955 to version 956.
Database 'DB_IWS_GNL_ST3' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 23161 pages in 1.344 seconds (134.628 MB/sec).
* run end
 
* restore: server[cnsistwsql070]>>[CNSISTWSQL100], database[DB_IWS_SCAN_ST3]>>[DB_IWS_SCAN_ST3]

(2 rows affected)
* run sql:
restore database DB_IWS_SCAN_ST3
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\cnsistwsql070_DB_IWS_SCAN_ST3_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'DB_IWS_SCAN' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_IWS_SCAN_ST3.mdf',
     move 'DB_IWS_SCAN_log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_IWS_SCAN_ST3_log.ldf',
     file = 1,
     medianame = 'cnsistwsql070_DB_IWS_SCAN_ST3_full_backup_2025_04_09_16_02_28',
     stats = 1;
1 percent processed.
2 percent processed.
3 percent processed.
4 percent processed.
5 percent processed.
6 percent processed.
7 percent processed.
8 percent processed.
9 percent processed.
10 percent processed.
11 percent processed.
12 percent processed.
13 percent processed.
14 percent processed.
15 percent processed.
16 percent processed.
17 percent processed.
18 percent processed.
19 percent processed.
20 percent processed.
21 percent processed.
22 percent processed.
23 percent processed.
24 percent processed.
25 percent processed.
26 percent processed.
27 percent processed.
28 percent processed.
29 percent processed.
30 percent processed.
31 percent processed.
32 percent processed.
33 percent processed.
34 percent processed.
35 percent processed.
36 percent processed.
37 percent processed.
38 percent processed.
39 percent processed.
40 percent processed.
41 percent processed.
42 percent processed.
43 percent processed.
44 percent processed.
45 percent processed.
46 percent processed.
47 percent processed.
48 percent processed.
49 percent processed.
50 percent processed.
51 percent processed.
52 percent processed.
53 percent processed.
54 percent processed.
55 percent processed.
56 percent processed.
57 percent processed.
58 percent processed.
59 percent processed.
60 percent processed.
61 percent processed.
62 percent processed.
63 percent processed.
64 percent processed.
65 percent processed.
66 percent processed.
67 percent processed.
68 percent processed.
69 percent processed.
70 percent processed.
71 percent processed.
72 percent processed.
73 percent processed.
74 percent processed.
75 percent processed.
76 percent processed.
77 percent processed.
78 percent processed.
79 percent processed.
80 percent processed.
81 percent processed.
82 percent processed.
83 percent processed.
84 percent processed.
85 percent processed.
86 percent processed.
87 percent processed.
88 percent processed.
89 percent processed.
90 percent processed.
91 percent processed.
92 percent processed.
93 percent processed.
94 percent processed.
95 percent processed.
96 percent processed.
97 percent processed.
98 percent processed.
99 percent processed.
100 percent processed.
Processed 140080 pages for database 'DB_IWS_SCAN_ST3', file 'DB_IWS_SCAN' on file 1.
Processed 1 pages for database 'DB_IWS_SCAN_ST3', file 'DB_IWS_SCAN_log' on file 1.
Converting database 'DB_IWS_SCAN_ST3' from version 904 to the current version 957.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 904 to version 905.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 905 to version 906.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 906 to version 907.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 907 to version 908.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 908 to version 909.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 909 to version 910.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 910 to version 911.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 911 to version 912.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 912 to version 913.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 913 to version 914.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 914 to version 915.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 915 to version 916.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 916 to version 917.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 917 to version 918.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 918 to version 919.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 919 to version 920.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 920 to version 921.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 921 to version 922.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 922 to version 923.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 923 to version 924.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 924 to version 925.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 925 to version 926.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 926 to version 927.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 927 to version 928.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 928 to version 929.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 929 to version 930.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 930 to version 931.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 931 to version 932.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 932 to version 933.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 933 to version 934.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 934 to version 935.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 935 to version 936.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 936 to version 937.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 937 to version 938.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 938 to version 939.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 939 to version 940.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 940 to version 941.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 941 to version 942.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 942 to version 943.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 943 to version 944.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 944 to version 945.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 945 to version 946.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 946 to version 947.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 947 to version 948.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 948 to version 949.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 949 to version 950.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 950 to version 951.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 951 to version 952.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 952 to version 953.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 953 to version 954.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 954 to version 955.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 955 to version 956.
Database 'DB_IWS_SCAN_ST3' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 140081 pages in 8.379 seconds (130.609 MB/sec).
* run end
 
* restore: server[cnsistwsql070]>>[CNSISTWSQL100], database[DB_SIGN_ST3]>>[DB_SIGN_ST3]

(2 rows affected)
* run sql:
restore database DB_SIGN_ST3
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\cnsistwsql070_DB_SIGN_ST3_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'DB_SIGN_Data' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_SIGN_ST3.mdf',
     move 'DB_SIGN_Log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_SIGN_ST3_log.ldf',
     file = 1,
     medianame = 'cnsistwsql070_DB_SIGN_ST3_full_backup_2025_04_09_16_02_28',
     stats = 1;
1 percent processed.
2 percent processed.
3 percent processed.
4 percent processed.
5 percent processed.
6 percent processed.
7 percent processed.
8 percent processed.
9 percent processed.
10 percent processed.
11 percent processed.
12 percent processed.
13 percent processed.
14 percent processed.
15 percent processed.
16 percent processed.
17 percent processed.
18 percent processed.
19 percent processed.
20 percent processed.
21 percent processed.
22 percent processed.
23 percent processed.
24 percent processed.
25 percent processed.
26 percent processed.
27 percent processed.
28 percent processed.
29 percent processed.
30 percent processed.
31 percent processed.
32 percent processed.
33 percent processed.
34 percent processed.
35 percent processed.
36 percent processed.
37 percent processed.
38 percent processed.
39 percent processed.
40 percent processed.
41 percent processed.
42 percent processed.
43 percent processed.
44 percent processed.
45 percent processed.
46 percent processed.
47 percent processed.
48 percent processed.
49 percent processed.
50 percent processed.
51 percent processed.
52 percent processed.
53 percent processed.
54 percent processed.
55 percent processed.
56 percent processed.
57 percent processed.
58 percent processed.
59 percent processed.
60 percent processed.
61 percent processed.
62 percent processed.
63 percent processed.
64 percent processed.
65 percent processed.
66 percent processed.
67 percent processed.
68 percent processed.
69 percent processed.
70 percent processed.
71 percent processed.
72 percent processed.
73 percent processed.
74 percent processed.
75 percent processed.
76 percent processed.
77 percent processed.
78 percent processed.
79 percent processed.
80 percent processed.
81 percent processed.
82 percent processed.
83 percent processed.
84 percent processed.
85 percent processed.
86 percent processed.
87 percent processed.
88 percent processed.
89 percent processed.
90 percent processed.
91 percent processed.
92 percent processed.
93 percent processed.
94 percent processed.
95 percent processed.
96 percent processed.
97 percent processed.
98 percent processed.
99 percent processed.
100 percent processed.
Processed 54560 pages for database 'DB_SIGN_ST3', file 'DB_SIGN_Data' on file 1.
Processed 1 pages for database 'DB_SIGN_ST3', file 'DB_SIGN_Log' on file 1.
Converting database 'DB_SIGN_ST3' from version 904 to the current version 957.
Database 'DB_SIGN_ST3' running the upgrade step from version 904 to version 905.
Database 'DB_SIGN_ST3' running the upgrade step from version 905 to version 906.
Database 'DB_SIGN_ST3' running the upgrade step from version 906 to version 907.
Database 'DB_SIGN_ST3' running the upgrade step from version 907 to version 908.
Database 'DB_SIGN_ST3' running the upgrade step from version 908 to version 909.
Database 'DB_SIGN_ST3' running the upgrade step from version 909 to version 910.
Database 'DB_SIGN_ST3' running the upgrade step from version 910 to version 911.
Database 'DB_SIGN_ST3' running the upgrade step from version 911 to version 912.
Database 'DB_SIGN_ST3' running the upgrade step from version 912 to version 913.
Database 'DB_SIGN_ST3' running the upgrade step from version 913 to version 914.
Database 'DB_SIGN_ST3' running the upgrade step from version 914 to version 915.
Database 'DB_SIGN_ST3' running the upgrade step from version 915 to version 916.
Database 'DB_SIGN_ST3' running the upgrade step from version 916 to version 917.
Database 'DB_SIGN_ST3' running the upgrade step from version 917 to version 918.
Database 'DB_SIGN_ST3' running the upgrade step from version 918 to version 919.
Database 'DB_SIGN_ST3' running the upgrade step from version 919 to version 920.
Database 'DB_SIGN_ST3' running the upgrade step from version 920 to version 921.
Database 'DB_SIGN_ST3' running the upgrade step from version 921 to version 922.
Database 'DB_SIGN_ST3' running the upgrade step from version 922 to version 923.
Database 'DB_SIGN_ST3' running the upgrade step from version 923 to version 924.
Database 'DB_SIGN_ST3' running the upgrade step from version 924 to version 925.
Database 'DB_SIGN_ST3' running the upgrade step from version 925 to version 926.
Database 'DB_SIGN_ST3' running the upgrade step from version 926 to version 927.
Database 'DB_SIGN_ST3' running the upgrade step from version 927 to version 928.
Database 'DB_SIGN_ST3' running the upgrade step from version 928 to version 929.
Database 'DB_SIGN_ST3' running the upgrade step from version 929 to version 930.
Database 'DB_SIGN_ST3' running the upgrade step from version 930 to version 931.
Database 'DB_SIGN_ST3' running the upgrade step from version 931 to version 932.
Database 'DB_SIGN_ST3' running the upgrade step from version 932 to version 933.
Database 'DB_SIGN_ST3' running the upgrade step from version 933 to version 934.
Database 'DB_SIGN_ST3' running the upgrade step from version 934 to version 935.
Database 'DB_SIGN_ST3' running the upgrade step from version 935 to version 936.
Database 'DB_SIGN_ST3' running the upgrade step from version 936 to version 937.
Database 'DB_SIGN_ST3' running the upgrade step from version 937 to version 938.
Database 'DB_SIGN_ST3' running the upgrade step from version 938 to version 939.
Database 'DB_SIGN_ST3' running the upgrade step from version 939 to version 940.
Database 'DB_SIGN_ST3' running the upgrade step from version 940 to version 941.
Database 'DB_SIGN_ST3' running the upgrade step from version 941 to version 942.
Database 'DB_SIGN_ST3' running the upgrade step from version 942 to version 943.
Database 'DB_SIGN_ST3' running the upgrade step from version 943 to version 944.
Database 'DB_SIGN_ST3' running the upgrade step from version 944 to version 945.
Database 'DB_SIGN_ST3' running the upgrade step from version 945 to version 946.
Database 'DB_SIGN_ST3' running the upgrade step from version 946 to version 947.
Database 'DB_SIGN_ST3' running the upgrade step from version 947 to version 948.
Database 'DB_SIGN_ST3' running the upgrade step from version 948 to version 949.
Database 'DB_SIGN_ST3' running the upgrade step from version 949 to version 950.
Database 'DB_SIGN_ST3' running the upgrade step from version 950 to version 951.
Database 'DB_SIGN_ST3' running the upgrade step from version 951 to version 952.
Database 'DB_SIGN_ST3' running the upgrade step from version 952 to version 953.
Database 'DB_SIGN_ST3' running the upgrade step from version 953 to version 954.
Database 'DB_SIGN_ST3' running the upgrade step from version 954 to version 955.
Database 'DB_SIGN_ST3' running the upgrade step from version 955 to version 956.
Database 'DB_SIGN_ST3' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 54561 pages in 2.885 seconds (147.747 MB/sec).
* run end
 
* restore: server[cnsistwsql080]>>[CNSISTWSQL100], database[DB_CATA_EXT_ST1]>>[DB_CATA_EXT_ST1]

(2 rows affected)
* run sql:
restore database DB_CATA_EXT_ST1
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\cnsistwsql080_DB_CATA_EXT_ST1_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'DB_CATA_EXT_Data' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_CATA_EXT_ST1.mdf',
     move 'DB_CATA_EXT_Log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_CATA_EXT_ST1_log.ldf',
     file = 1,
     medianame = 'cnsistwsql080_DB_CATA_EXT_ST1_full_backup_2025_04_09_16_02_28',
     stats = 1;
1 percent processed.
2 percent processed.
3 percent processed.
4 percent processed.
5 percent processed.
6 percent processed.
7 percent processed.
8 percent processed.
9 percent processed.
10 percent processed.
11 percent processed.
12 percent processed.
13 percent processed.
14 percent processed.
15 percent processed.
16 percent processed.
17 percent processed.
18 percent processed.
19 percent processed.
20 percent processed.
21 percent processed.
22 percent processed.
23 percent processed.
24 percent processed.
25 percent processed.
26 percent processed.
27 percent processed.
28 percent processed.
29 percent processed.
30 percent processed.
31 percent processed.
32 percent processed.
33 percent processed.
34 percent processed.
35 percent processed.
36 percent processed.
37 percent processed.
38 percent processed.
39 percent processed.
40 percent processed.
41 percent processed.
42 percent processed.
43 percent processed.
44 percent processed.
45 percent processed.
46 percent processed.
47 percent processed.
48 percent processed.
49 percent processed.
50 percent processed.
51 percent processed.
52 percent processed.
53 percent processed.
54 percent processed.
55 percent processed.
56 percent processed.
57 percent processed.
58 percent processed.
59 percent processed.
60 percent processed.
61 percent processed.
62 percent processed.
63 percent processed.
64 percent processed.
65 percent processed.
66 percent processed.
67 percent processed.
68 percent processed.
69 percent processed.
70 percent processed.
71 percent processed.
72 percent processed.
73 percent processed.
74 percent processed.
75 percent processed.
76 percent processed.
77 percent processed.
78 percent processed.
79 percent processed.
80 percent processed.
81 percent processed.
82 percent processed.
83 percent processed.
84 percent processed.
85 percent processed.
86 percent processed.
87 percent processed.
88 percent processed.
89 percent processed.
90 percent processed.
91 percent processed.
92 percent processed.
93 percent processed.
94 percent processed.
95 percent processed.
96 percent processed.
97 percent processed.
98 percent processed.
99 percent processed.
100 percent processed.
Processed 13344 pages for database 'DB_CATA_EXT_ST1', file 'DB_CATA_EXT_Data' on file 1.
Processed 1 pages for database 'DB_CATA_EXT_ST1', file 'DB_CATA_EXT_Log' on file 1.
Converting database 'DB_CATA_EXT_ST1' from version 904 to the current version 957.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 904 to version 905.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 905 to version 906.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 906 to version 907.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 907 to version 908.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 908 to version 909.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 909 to version 910.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 910 to version 911.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 911 to version 912.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 912 to version 913.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 913 to version 914.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 914 to version 915.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 915 to version 916.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 916 to version 917.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 917 to version 918.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 918 to version 919.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 919 to version 920.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 920 to version 921.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 921 to version 922.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 922 to version 923.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 923 to version 924.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 924 to version 925.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 925 to version 926.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 926 to version 927.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 927 to version 928.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 928 to version 929.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 929 to version 930.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 930 to version 931.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 931 to version 932.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 932 to version 933.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 933 to version 934.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 934 to version 935.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 935 to version 936.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 936 to version 937.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 937 to version 938.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 938 to version 939.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 939 to version 940.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 940 to version 941.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 941 to version 942.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 942 to version 943.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 943 to version 944.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 944 to version 945.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 945 to version 946.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 946 to version 947.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 947 to version 948.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 948 to version 949.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 949 to version 950.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 950 to version 951.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 951 to version 952.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 952 to version 953.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 953 to version 954.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 954 to version 955.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 955 to version 956.
Database 'DB_CATA_EXT_ST1' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 13345 pages in 0.808 seconds (129.024 MB/sec).
* run end
 
* restore: server[cnsistwsql080]>>[CNSISTWSQL100], database[DB_CATA_ST1]>>[DB_CATA_ST1]

(2 rows affected)
* run sql:
restore database DB_CATA_ST1
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\cnsistwsql080_DB_CATA_ST1_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'DB_CATA_Data' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_CATA_ST1.mdf',
     move 'DB_CATA_log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_CATA_ST1_log.ldf',
     file = 1,
     medianame = 'cnsistwsql080_DB_CATA_ST1_full_backup_2025_04_09_16_02_28',
     stats = 1;
1 percent processed.
2 percent processed.
3 percent processed.
4 percent processed.
5 percent processed.
6 percent processed.
7 percent processed.
8 percent processed.
9 percent processed.
10 percent processed.
11 percent processed.
12 percent processed.
13 percent processed.
14 percent processed.
15 percent processed.
16 percent processed.
17 percent processed.
18 percent processed.
19 percent processed.
20 percent processed.
21 percent processed.
22 percent processed.
23 percent processed.
24 percent processed.
25 percent processed.
26 percent processed.
27 percent processed.
28 percent processed.
29 percent processed.
30 percent processed.
31 percent processed.
32 percent processed.
33 percent processed.
34 percent processed.
35 percent processed.
36 percent processed.
37 percent processed.
38 percent processed.
39 percent processed.
40 percent processed.
41 percent processed.
42 percent processed.
43 percent processed.
44 percent processed.
45 percent processed.
46 percent processed.
47 percent processed.
48 percent processed.
49 percent processed.
50 percent processed.
51 percent processed.
52 percent processed.
53 percent processed.
54 percent processed.
55 percent processed.
56 percent processed.
57 percent processed.
58 percent processed.
59 percent processed.
60 percent processed.
61 percent processed.
62 percent processed.
63 percent processed.
64 percent processed.
65 percent processed.
66 percent processed.
67 percent processed.
68 percent processed.
69 percent processed.
70 percent processed.
71 percent processed.
72 percent processed.
73 percent processed.
74 percent processed.
75 percent processed.
76 percent processed.
77 percent processed.
78 percent processed.
79 percent processed.
80 percent processed.
81 percent processed.
82 percent processed.
83 percent processed.
84 percent processed.
85 percent processed.
86 percent processed.
87 percent processed.
88 percent processed.
89 percent processed.
90 percent processed.
91 percent processed.
92 percent processed.
93 percent processed.
94 percent processed.
95 percent processed.
96 percent processed.
97 percent processed.
98 percent processed.
99 percent processed.
100 percent processed.
Processed 960 pages for database 'DB_CATA_ST1', file 'DB_CATA_Data' on file 1.
Processed 1 pages for database 'DB_CATA_ST1', file 'DB_CATA_log' on file 1.
Converting database 'DB_CATA_ST1' from version 904 to the current version 957.
Database 'DB_CATA_ST1' running the upgrade step from version 904 to version 905.
Database 'DB_CATA_ST1' running the upgrade step from version 905 to version 906.
Database 'DB_CATA_ST1' running the upgrade step from version 906 to version 907.
Database 'DB_CATA_ST1' running the upgrade step from version 907 to version 908.
Database 'DB_CATA_ST1' running the upgrade step from version 908 to version 909.
Database 'DB_CATA_ST1' running the upgrade step from version 909 to version 910.
Database 'DB_CATA_ST1' running the upgrade step from version 910 to version 911.
Database 'DB_CATA_ST1' running the upgrade step from version 911 to version 912.
Database 'DB_CATA_ST1' running the upgrade step from version 912 to version 913.
Database 'DB_CATA_ST1' running the upgrade step from version 913 to version 914.
Database 'DB_CATA_ST1' running the upgrade step from version 914 to version 915.
Database 'DB_CATA_ST1' running the upgrade step from version 915 to version 916.
Database 'DB_CATA_ST1' running the upgrade step from version 916 to version 917.
Database 'DB_CATA_ST1' running the upgrade step from version 917 to version 918.
Database 'DB_CATA_ST1' running the upgrade step from version 918 to version 919.
Database 'DB_CATA_ST1' running the upgrade step from version 919 to version 920.
Database 'DB_CATA_ST1' running the upgrade step from version 920 to version 921.
Database 'DB_CATA_ST1' running the upgrade step from version 921 to version 922.
Database 'DB_CATA_ST1' running the upgrade step from version 922 to version 923.
Database 'DB_CATA_ST1' running the upgrade step from version 923 to version 924.
Database 'DB_CATA_ST1' running the upgrade step from version 924 to version 925.
Database 'DB_CATA_ST1' running the upgrade step from version 925 to version 926.
Database 'DB_CATA_ST1' running the upgrade step from version 926 to version 927.
Database 'DB_CATA_ST1' running the upgrade step from version 927 to version 928.
Database 'DB_CATA_ST1' running the upgrade step from version 928 to version 929.
Database 'DB_CATA_ST1' running the upgrade step from version 929 to version 930.
Database 'DB_CATA_ST1' running the upgrade step from version 930 to version 931.
Database 'DB_CATA_ST1' running the upgrade step from version 931 to version 932.
Database 'DB_CATA_ST1' running the upgrade step from version 932 to version 933.
Database 'DB_CATA_ST1' running the upgrade step from version 933 to version 934.
Database 'DB_CATA_ST1' running the upgrade step from version 934 to version 935.
Database 'DB_CATA_ST1' running the upgrade step from version 935 to version 936.
Database 'DB_CATA_ST1' running the upgrade step from version 936 to version 937.
Database 'DB_CATA_ST1' running the upgrade step from version 937 to version 938.
Database 'DB_CATA_ST1' running the upgrade step from version 938 to version 939.
Database 'DB_CATA_ST1' running the upgrade step from version 939 to version 940.
Database 'DB_CATA_ST1' running the upgrade step from version 940 to version 941.
Database 'DB_CATA_ST1' running the upgrade step from version 941 to version 942.
Database 'DB_CATA_ST1' running the upgrade step from version 942 to version 943.
Database 'DB_CATA_ST1' running the upgrade step from version 943 to version 944.
Database 'DB_CATA_ST1' running the upgrade step from version 944 to version 945.
Database 'DB_CATA_ST1' running the upgrade step from version 945 to version 946.
Database 'DB_CATA_ST1' running the upgrade step from version 946 to version 947.
Database 'DB_CATA_ST1' running the upgrade step from version 947 to version 948.
Database 'DB_CATA_ST1' running the upgrade step from version 948 to version 949.
Database 'DB_CATA_ST1' running the upgrade step from version 949 to version 950.
Database 'DB_CATA_ST1' running the upgrade step from version 950 to version 951.
Database 'DB_CATA_ST1' running the upgrade step from version 951 to version 952.
Database 'DB_CATA_ST1' running the upgrade step from version 952 to version 953.
Database 'DB_CATA_ST1' running the upgrade step from version 953 to version 954.
Database 'DB_CATA_ST1' running the upgrade step from version 954 to version 955.
Database 'DB_CATA_ST1' running the upgrade step from version 955 to version 956.
Database 'DB_CATA_ST1' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 961 pages in 0.104 seconds (72.129 MB/sec).
* run end
 
* restore: server[cnsistwsql080]>>[CNSISTWSQL100], database[DB_DC1_ST1]>>[DB_DC1_ST1]

(2 rows affected)
* run sql:
restore database DB_DC1_ST1
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\cnsistwsql080_DB_DC1_ST1_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'DB_DC1_Data' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_DC1_ST1.mdf',
     move 'DB_DC1_log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_DC1_ST1_log.ldf',
     file = 1,
     medianame = 'cnsistwsql080_DB_DC1_ST1_full_backup_2025_04_09_16_02_28',
     stats = 1;
1 percent processed.
2 percent processed.
3 percent processed.
4 percent processed.
5 percent processed.
6 percent processed.
7 percent processed.
8 percent processed.
9 percent processed.
10 percent processed.
11 percent processed.
12 percent processed.
13 percent processed.
14 percent processed.
15 percent processed.
16 percent processed.
17 percent processed.
18 percent processed.
19 percent processed.
20 percent processed.
21 percent processed.
22 percent processed.
23 percent processed.
24 percent processed.
25 percent processed.
26 percent processed.
27 percent processed.
28 percent processed.
29 percent processed.
30 percent processed.
31 percent processed.
32 percent processed.
33 percent processed.
34 percent processed.
35 percent processed.
36 percent processed.
37 percent processed.
38 percent processed.
39 percent processed.
40 percent processed.
41 percent processed.
42 percent processed.
43 percent processed.
44 percent processed.
45 percent processed.
46 percent processed.
47 percent processed.
48 percent processed.
49 percent processed.
50 percent processed.
51 percent processed.
52 percent processed.
53 percent processed.
54 percent processed.
55 percent processed.
56 percent processed.
57 percent processed.
58 percent processed.
59 percent processed.
60 percent processed.
61 percent processed.
62 percent processed.
63 percent processed.
64 percent processed.
65 percent processed.
66 percent processed.
67 percent processed.
68 percent processed.
69 percent processed.
70 percent processed.
71 percent processed.
72 percent processed.
73 percent processed.
74 percent processed.
75 percent processed.
76 percent processed.
77 percent processed.
78 percent processed.
79 percent processed.
80 percent processed.
81 percent processed.
82 percent processed.
83 percent processed.
84 percent processed.
85 percent processed.
86 percent processed.
87 percent processed.
88 percent processed.
89 percent processed.
90 percent processed.
91 percent processed.
92 percent processed.
93 percent processed.
94 percent processed.
95 percent processed.
96 percent processed.
97 percent processed.
98 percent processed.
99 percent processed.
100 percent processed.
Processed 107448 pages for database 'DB_DC1_ST1', file 'DB_DC1_Data' on file 1.
Processed 1 pages for database 'DB_DC1_ST1', file 'DB_DC1_log' on file 1.
Converting database 'DB_DC1_ST1' from version 904 to the current version 957.
Database 'DB_DC1_ST1' running the upgrade step from version 904 to version 905.
Database 'DB_DC1_ST1' running the upgrade step from version 905 to version 906.
Database 'DB_DC1_ST1' running the upgrade step from version 906 to version 907.
Database 'DB_DC1_ST1' running the upgrade step from version 907 to version 908.
Database 'DB_DC1_ST1' running the upgrade step from version 908 to version 909.
Database 'DB_DC1_ST1' running the upgrade step from version 909 to version 910.
Database 'DB_DC1_ST1' running the upgrade step from version 910 to version 911.
Database 'DB_DC1_ST1' running the upgrade step from version 911 to version 912.
Database 'DB_DC1_ST1' running the upgrade step from version 912 to version 913.
Database 'DB_DC1_ST1' running the upgrade step from version 913 to version 914.
Database 'DB_DC1_ST1' running the upgrade step from version 914 to version 915.
Database 'DB_DC1_ST1' running the upgrade step from version 915 to version 916.
Database 'DB_DC1_ST1' running the upgrade step from version 916 to version 917.
Database 'DB_DC1_ST1' running the upgrade step from version 917 to version 918.
Database 'DB_DC1_ST1' running the upgrade step from version 918 to version 919.
Database 'DB_DC1_ST1' running the upgrade step from version 919 to version 920.
Database 'DB_DC1_ST1' running the upgrade step from version 920 to version 921.
Database 'DB_DC1_ST1' running the upgrade step from version 921 to version 922.
Database 'DB_DC1_ST1' running the upgrade step from version 922 to version 923.
Database 'DB_DC1_ST1' running the upgrade step from version 923 to version 924.
Database 'DB_DC1_ST1' running the upgrade step from version 924 to version 925.
Database 'DB_DC1_ST1' running the upgrade step from version 925 to version 926.
Database 'DB_DC1_ST1' running the upgrade step from version 926 to version 927.
Database 'DB_DC1_ST1' running the upgrade step from version 927 to version 928.
Database 'DB_DC1_ST1' running the upgrade step from version 928 to version 929.
Database 'DB_DC1_ST1' running the upgrade step from version 929 to version 930.
Database 'DB_DC1_ST1' running the upgrade step from version 930 to version 931.
Database 'DB_DC1_ST1' running the upgrade step from version 931 to version 932.
Database 'DB_DC1_ST1' running the upgrade step from version 932 to version 933.
Database 'DB_DC1_ST1' running the upgrade step from version 933 to version 934.
Database 'DB_DC1_ST1' running the upgrade step from version 934 to version 935.
Database 'DB_DC1_ST1' running the upgrade step from version 935 to version 936.
Database 'DB_DC1_ST1' running the upgrade step from version 936 to version 937.
Database 'DB_DC1_ST1' running the upgrade step from version 937 to version 938.
Database 'DB_DC1_ST1' running the upgrade step from version 938 to version 939.
Database 'DB_DC1_ST1' running the upgrade step from version 939 to version 940.
Database 'DB_DC1_ST1' running the upgrade step from version 940 to version 941.
Database 'DB_DC1_ST1' running the upgrade step from version 941 to version 942.
Database 'DB_DC1_ST1' running the upgrade step from version 942 to version 943.
Database 'DB_DC1_ST1' running the upgrade step from version 943 to version 944.
Database 'DB_DC1_ST1' running the upgrade step from version 944 to version 945.
Database 'DB_DC1_ST1' running the upgrade step from version 945 to version 946.
Database 'DB_DC1_ST1' running the upgrade step from version 946 to version 947.
Database 'DB_DC1_ST1' running the upgrade step from version 947 to version 948.
Database 'DB_DC1_ST1' running the upgrade step from version 948 to version 949.
Database 'DB_DC1_ST1' running the upgrade step from version 949 to version 950.
Database 'DB_DC1_ST1' running the upgrade step from version 950 to version 951.
Database 'DB_DC1_ST1' running the upgrade step from version 951 to version 952.
Database 'DB_DC1_ST1' running the upgrade step from version 952 to version 953.
Database 'DB_DC1_ST1' running the upgrade step from version 953 to version 954.
Database 'DB_DC1_ST1' running the upgrade step from version 954 to version 955.
Database 'DB_DC1_ST1' running the upgrade step from version 955 to version 956.
Database 'DB_DC1_ST1' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 107449 pages in 5.357 seconds (156.699 MB/sec).
* run end
 
* restore: server[cnsistwsql080]>>[CNSISTWSQL100], database[DB_IWS_GNL_ST1]>>[DB_IWS_GNL_ST1]

(2 rows affected)
* run sql:
restore database DB_IWS_GNL_ST1
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\cnsistwsql080_DB_IWS_GNL_ST1_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'DB_IWS_GNL_Data' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_IWS_GNL_ST1.mdf',
     move 'DB_IWS_GNL_Log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_IWS_GNL_ST1_log.ldf',
     file = 1,
     medianame = 'cnsistwsql080_DB_IWS_GNL_ST1_full_backup_2025_04_09_16_02_28',
     stats = 1;
1 percent processed.
2 percent processed.
3 percent processed.
4 percent processed.
5 percent processed.
6 percent processed.
7 percent processed.
8 percent processed.
9 percent processed.
10 percent processed.
11 percent processed.
12 percent processed.
13 percent processed.
14 percent processed.
15 percent processed.
16 percent processed.
17 percent processed.
18 percent processed.
19 percent processed.
20 percent processed.
21 percent processed.
22 percent processed.
23 percent processed.
24 percent processed.
25 percent processed.
26 percent processed.
27 percent processed.
28 percent processed.
29 percent processed.
30 percent processed.
31 percent processed.
32 percent processed.
33 percent processed.
34 percent processed.
35 percent processed.
36 percent processed.
37 percent processed.
38 percent processed.
39 percent processed.
40 percent processed.
41 percent processed.
42 percent processed.
43 percent processed.
44 percent processed.
45 percent processed.
46 percent processed.
47 percent processed.
48 percent processed.
49 percent processed.
50 percent processed.
51 percent processed.
52 percent processed.
53 percent processed.
54 percent processed.
55 percent processed.
56 percent processed.
57 percent processed.
58 percent processed.
59 percent processed.
60 percent processed.
61 percent processed.
62 percent processed.
63 percent processed.
64 percent processed.
65 percent processed.
66 percent processed.
67 percent processed.
68 percent processed.
69 percent processed.
70 percent processed.
71 percent processed.
72 percent processed.
73 percent processed.
74 percent processed.
75 percent processed.
76 percent processed.
77 percent processed.
78 percent processed.
79 percent processed.
80 percent processed.
81 percent processed.
82 percent processed.
83 percent processed.
84 percent processed.
85 percent processed.
86 percent processed.
87 percent processed.
88 percent processed.
89 percent processed.
90 percent processed.
91 percent processed.
92 percent processed.
93 percent processed.
94 percent processed.
95 percent processed.
96 percent processed.
97 percent processed.
98 percent processed.
99 percent processed.
100 percent processed.
Processed 22096 pages for database 'DB_IWS_GNL_ST1', file 'DB_IWS_GNL_Data' on file 1.
Processed 1 pages for database 'DB_IWS_GNL_ST1', file 'DB_IWS_GNL_Log' on file 1.
Converting database 'DB_IWS_GNL_ST1' from version 904 to the current version 957.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 904 to version 905.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 905 to version 906.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 906 to version 907.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 907 to version 908.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 908 to version 909.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 909 to version 910.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 910 to version 911.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 911 to version 912.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 912 to version 913.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 913 to version 914.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 914 to version 915.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 915 to version 916.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 916 to version 917.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 917 to version 918.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 918 to version 919.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 919 to version 920.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 920 to version 921.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 921 to version 922.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 922 to version 923.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 923 to version 924.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 924 to version 925.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 925 to version 926.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 926 to version 927.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 927 to version 928.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 928 to version 929.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 929 to version 930.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 930 to version 931.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 931 to version 932.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 932 to version 933.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 933 to version 934.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 934 to version 935.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 935 to version 936.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 936 to version 937.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 937 to version 938.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 938 to version 939.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 939 to version 940.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 940 to version 941.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 941 to version 942.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 942 to version 943.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 943 to version 944.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 944 to version 945.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 945 to version 946.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 946 to version 947.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 947 to version 948.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 948 to version 949.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 949 to version 950.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 950 to version 951.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 951 to version 952.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 952 to version 953.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 953 to version 954.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 954 to version 955.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 955 to version 956.
Database 'DB_IWS_GNL_ST1' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 22097 pages in 1.345 seconds (128.347 MB/sec).
* run end
 
* restore: server[cnsistwsql080]>>[CNSISTWSQL100], database[DB_IWS_SCAN_ST1]>>[DB_IWS_SCAN_ST1]

(2 rows affected)
* run sql:
restore database DB_IWS_SCAN_ST1
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\cnsistwsql080_DB_IWS_SCAN_ST1_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'DB_IWS_SCAN' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_IWS_SCAN_ST1.mdf',
     move 'DB_IWS_SCAN_log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_IWS_SCAN_ST1_log.ldf',
     file = 1,
     medianame = 'cnsistwsql080_DB_IWS_SCAN_ST1_full_backup_2025_04_09_16_02_28',
     stats = 1;
1 percent processed.
2 percent processed.
3 percent processed.
4 percent processed.
5 percent processed.
6 percent processed.
7 percent processed.
8 percent processed.
9 percent processed.
10 percent processed.
11 percent processed.
12 percent processed.
13 percent processed.
14 percent processed.
15 percent processed.
16 percent processed.
17 percent processed.
18 percent processed.
19 percent processed.
20 percent processed.
21 percent processed.
22 percent processed.
23 percent processed.
24 percent processed.
25 percent processed.
26 percent processed.
27 percent processed.
28 percent processed.
29 percent processed.
30 percent processed.
31 percent processed.
32 percent processed.
33 percent processed.
34 percent processed.
35 percent processed.
36 percent processed.
37 percent processed.
38 percent processed.
39 percent processed.
40 percent processed.
41 percent processed.
42 percent processed.
43 percent processed.
44 percent processed.
45 percent processed.
46 percent processed.
47 percent processed.
48 percent processed.
49 percent processed.
50 percent processed.
51 percent processed.
52 percent processed.
53 percent processed.
54 percent processed.
55 percent processed.
56 percent processed.
57 percent processed.
58 percent processed.
59 percent processed.
60 percent processed.
61 percent processed.
62 percent processed.
63 percent processed.
64 percent processed.
65 percent processed.
66 percent processed.
67 percent processed.
68 percent processed.
69 percent processed.
70 percent processed.
71 percent processed.
72 percent processed.
73 percent processed.
74 percent processed.
75 percent processed.
76 percent processed.
77 percent processed.
78 percent processed.
79 percent processed.
80 percent processed.
81 percent processed.
82 percent processed.
83 percent processed.
84 percent processed.
85 percent processed.
86 percent processed.
87 percent processed.
88 percent processed.
89 percent processed.
90 percent processed.
91 percent processed.
92 percent processed.
93 percent processed.
94 percent processed.
95 percent processed.
96 percent processed.
97 percent processed.
98 percent processed.
99 percent processed.
100 percent processed.
Processed 132664 pages for database 'DB_IWS_SCAN_ST1', file 'DB_IWS_SCAN' on file 1.
Processed 1 pages for database 'DB_IWS_SCAN_ST1', file 'DB_IWS_SCAN_log' on file 1.
Converting database 'DB_IWS_SCAN_ST1' from version 904 to the current version 957.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 904 to version 905.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 905 to version 906.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 906 to version 907.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 907 to version 908.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 908 to version 909.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 909 to version 910.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 910 to version 911.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 911 to version 912.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 912 to version 913.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 913 to version 914.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 914 to version 915.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 915 to version 916.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 916 to version 917.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 917 to version 918.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 918 to version 919.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 919 to version 920.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 920 to version 921.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 921 to version 922.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 922 to version 923.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 923 to version 924.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 924 to version 925.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 925 to version 926.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 926 to version 927.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 927 to version 928.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 928 to version 929.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 929 to version 930.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 930 to version 931.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 931 to version 932.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 932 to version 933.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 933 to version 934.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 934 to version 935.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 935 to version 936.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 936 to version 937.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 937 to version 938.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 938 to version 939.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 939 to version 940.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 940 to version 941.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 941 to version 942.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 942 to version 943.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 943 to version 944.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 944 to version 945.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 945 to version 946.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 946 to version 947.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 947 to version 948.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 948 to version 949.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 949 to version 950.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 950 to version 951.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 951 to version 952.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 952 to version 953.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 953 to version 954.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 954 to version 955.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 955 to version 956.
Database 'DB_IWS_SCAN_ST1' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 132665 pages in 7.875 seconds (131.611 MB/sec).
* run end
 
* restore: server[cnsistwsql080]>>[CNSISTWSQL100], database[DB_SIGN_ST1]>>[DB_SIGN_ST1]

(2 rows affected)
* run sql:
restore database DB_SIGN_ST1
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\cnsistwsql080_DB_SIGN_ST1_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'DB_SIGN_Data' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_SIGN_ST1.mdf',
     move 'DB_SIGN_Log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_SIGN_ST1_log.ldf',
     file = 1,
     medianame = 'cnsistwsql080_DB_SIGN_ST1_full_backup_2025_04_09_16_02_28',
     stats = 1;
1 percent processed.
2 percent processed.
3 percent processed.
4 percent processed.
5 percent processed.
6 percent processed.
7 percent processed.
8 percent processed.
9 percent processed.
10 percent processed.
11 percent processed.
12 percent processed.
13 percent processed.
14 percent processed.
15 percent processed.
16 percent processed.
17 percent processed.
18 percent processed.
19 percent processed.
20 percent processed.
21 percent processed.
22 percent processed.
23 percent processed.
24 percent processed.
25 percent processed.
26 percent processed.
27 percent processed.
28 percent processed.
29 percent processed.
30 percent processed.
31 percent processed.
32 percent processed.
33 percent processed.
34 percent processed.
35 percent processed.
36 percent processed.
37 percent processed.
38 percent processed.
39 percent processed.
40 percent processed.
41 percent processed.
42 percent processed.
43 percent processed.
44 percent processed.
45 percent processed.
46 percent processed.
47 percent processed.
48 percent processed.
49 percent processed.
50 percent processed.
51 percent processed.
52 percent processed.
53 percent processed.
54 percent processed.
55 percent processed.
56 percent processed.
57 percent processed.
58 percent processed.
59 percent processed.
60 percent processed.
61 percent processed.
62 percent processed.
63 percent processed.
64 percent processed.
65 percent processed.
66 percent processed.
67 percent processed.
68 percent processed.
69 percent processed.
70 percent processed.
71 percent processed.
72 percent processed.
73 percent processed.
74 percent processed.
75 percent processed.
76 percent processed.
77 percent processed.
78 percent processed.
79 percent processed.
80 percent processed.
81 percent processed.
82 percent processed.
83 percent processed.
84 percent processed.
85 percent processed.
86 percent processed.
87 percent processed.
88 percent processed.
89 percent processed.
90 percent processed.
91 percent processed.
92 percent processed.
93 percent processed.
94 percent processed.
95 percent processed.
96 percent processed.
97 percent processed.
98 percent processed.
99 percent processed.
100 percent processed.
Processed 86552 pages for database 'DB_SIGN_ST1', file 'DB_SIGN_Data' on file 1.
Processed 1 pages for database 'DB_SIGN_ST1', file 'DB_SIGN_Log' on file 1.
Converting database 'DB_SIGN_ST1' from version 904 to the current version 957.
Database 'DB_SIGN_ST1' running the upgrade step from version 904 to version 905.
Database 'DB_SIGN_ST1' running the upgrade step from version 905 to version 906.
Database 'DB_SIGN_ST1' running the upgrade step from version 906 to version 907.
Database 'DB_SIGN_ST1' running the upgrade step from version 907 to version 908.
Database 'DB_SIGN_ST1' running the upgrade step from version 908 to version 909.
Database 'DB_SIGN_ST1' running the upgrade step from version 909 to version 910.
Database 'DB_SIGN_ST1' running the upgrade step from version 910 to version 911.
Database 'DB_SIGN_ST1' running the upgrade step from version 911 to version 912.
Database 'DB_SIGN_ST1' running the upgrade step from version 912 to version 913.
Database 'DB_SIGN_ST1' running the upgrade step from version 913 to version 914.
Database 'DB_SIGN_ST1' running the upgrade step from version 914 to version 915.
Database 'DB_SIGN_ST1' running the upgrade step from version 915 to version 916.
Database 'DB_SIGN_ST1' running the upgrade step from version 916 to version 917.
Database 'DB_SIGN_ST1' running the upgrade step from version 917 to version 918.
Database 'DB_SIGN_ST1' running the upgrade step from version 918 to version 919.
Database 'DB_SIGN_ST1' running the upgrade step from version 919 to version 920.
Database 'DB_SIGN_ST1' running the upgrade step from version 920 to version 921.
Database 'DB_SIGN_ST1' running the upgrade step from version 921 to version 922.
Database 'DB_SIGN_ST1' running the upgrade step from version 922 to version 923.
Database 'DB_SIGN_ST1' running the upgrade step from version 923 to version 924.
Database 'DB_SIGN_ST1' running the upgrade step from version 924 to version 925.
Database 'DB_SIGN_ST1' running the upgrade step from version 925 to version 926.
Database 'DB_SIGN_ST1' running the upgrade step from version 926 to version 927.
Database 'DB_SIGN_ST1' running the upgrade step from version 927 to version 928.
Database 'DB_SIGN_ST1' running the upgrade step from version 928 to version 929.
Database 'DB_SIGN_ST1' running the upgrade step from version 929 to version 930.
Database 'DB_SIGN_ST1' running the upgrade step from version 930 to version 931.
Database 'DB_SIGN_ST1' running the upgrade step from version 931 to version 932.
Database 'DB_SIGN_ST1' running the upgrade step from version 932 to version 933.
Database 'DB_SIGN_ST1' running the upgrade step from version 933 to version 934.
Database 'DB_SIGN_ST1' running the upgrade step from version 934 to version 935.
Database 'DB_SIGN_ST1' running the upgrade step from version 935 to version 936.
Database 'DB_SIGN_ST1' running the upgrade step from version 936 to version 937.
Database 'DB_SIGN_ST1' running the upgrade step from version 937 to version 938.
Database 'DB_SIGN_ST1' running the upgrade step from version 938 to version 939.
Database 'DB_SIGN_ST1' running the upgrade step from version 939 to version 940.
Database 'DB_SIGN_ST1' running the upgrade step from version 940 to version 941.
Database 'DB_SIGN_ST1' running the upgrade step from version 941 to version 942.
Database 'DB_SIGN_ST1' running the upgrade step from version 942 to version 943.
Database 'DB_SIGN_ST1' running the upgrade step from version 943 to version 944.
Database 'DB_SIGN_ST1' running the upgrade step from version 944 to version 945.
Database 'DB_SIGN_ST1' running the upgrade step from version 945 to version 946.
Database 'DB_SIGN_ST1' running the upgrade step from version 946 to version 947.
Database 'DB_SIGN_ST1' running the upgrade step from version 947 to version 948.
Database 'DB_SIGN_ST1' running the upgrade step from version 948 to version 949.
Database 'DB_SIGN_ST1' running the upgrade step from version 949 to version 950.
Database 'DB_SIGN_ST1' running the upgrade step from version 950 to version 951.
Database 'DB_SIGN_ST1' running the upgrade step from version 951 to version 952.
Database 'DB_SIGN_ST1' running the upgrade step from version 952 to version 953.
Database 'DB_SIGN_ST1' running the upgrade step from version 953 to version 954.
Database 'DB_SIGN_ST1' running the upgrade step from version 954 to version 955.
Database 'DB_SIGN_ST1' running the upgrade step from version 955 to version 956.
Database 'DB_SIGN_ST1' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 86553 pages in 3.186 seconds (212.237 MB/sec).
* run end
 

(19 rows affected)

Completion time: 2025-04-09T16:58:37.5696788+08:00








Warning! The maximum key length for a nonclustered index is 1700 bytes. The index 'UQ__#ST_DB_M__D5DCD2AA2CA2B0A8' has maximum length of 2040 bytes. For some combination of large values, the insert/update operation will fail.

(10 rows affected)
* restore: server[CNACLTWCPD403S]>>[CNSISTWSQL100], database[DB_CATA]>>[DB_CATA_ST4]

(2 rows affected)
* run sql:
restore database DB_CATA_ST4
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\CNACLTWCPD403S_DB_CATA_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'DB_CATA_Data' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_CATA_ST4.mdf',
     move 'DB_CATA_log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_CATA_ST4_log.ldf',
     file = 1,
     --medianame = 'CNACLTWCPD403S_DB_CATA_full_backup_2025_04_09_16_02_28',
     stats = 20;
24 percent processed.
43 percent processed.
61 percent processed.
80 percent processed.
100 percent processed.
Processed 2072 pages for database 'DB_CATA_ST4', file 'DB_CATA_Data' on file 1.
Processed 2 pages for database 'DB_CATA_ST4', file 'DB_CATA_log' on file 1.
Converting database 'DB_CATA_ST4' from version 852 to the current version 957.
Database 'DB_CATA_ST4' running the upgrade step from version 852 to version 853.
Database 'DB_CATA_ST4' running the upgrade step from version 853 to version 854.
Database 'DB_CATA_ST4' running the upgrade step from version 854 to version 855.
Database 'DB_CATA_ST4' running the upgrade step from version 855 to version 856.
Database 'DB_CATA_ST4' running the upgrade step from version 856 to version 857.
Database 'DB_CATA_ST4' running the upgrade step from version 857 to version 858.
Database 'DB_CATA_ST4' running the upgrade step from version 858 to version 859.
Database 'DB_CATA_ST4' running the upgrade step from version 859 to version 860.
Database 'DB_CATA_ST4' running the upgrade step from version 860 to version 861.
Database 'DB_CATA_ST4' running the upgrade step from version 861 to version 862.
Database 'DB_CATA_ST4' running the upgrade step from version 862 to version 863.
Database 'DB_CATA_ST4' running the upgrade step from version 863 to version 864.
Database 'DB_CATA_ST4' running the upgrade step from version 864 to version 865.
Database 'DB_CATA_ST4' running the upgrade step from version 865 to version 866.
Database 'DB_CATA_ST4' running the upgrade step from version 866 to version 867.
Database 'DB_CATA_ST4' running the upgrade step from version 867 to version 868.
Database 'DB_CATA_ST4' running the upgrade step from version 868 to version 869.
Database 'DB_CATA_ST4' running the upgrade step from version 869 to version 875.
Database 'DB_CATA_ST4' running the upgrade step from version 875 to version 876.
Database 'DB_CATA_ST4' running the upgrade step from version 876 to version 877.
Database 'DB_CATA_ST4' running the upgrade step from version 877 to version 878.
Database 'DB_CATA_ST4' running the upgrade step from version 878 to version 879.
Database 'DB_CATA_ST4' running the upgrade step from version 879 to version 880.
Database 'DB_CATA_ST4' running the upgrade step from version 880 to version 881.
Database 'DB_CATA_ST4' running the upgrade step from version 881 to version 882.
Database 'DB_CATA_ST4' running the upgrade step from version 882 to version 883.
Database 'DB_CATA_ST4' running the upgrade step from version 883 to version 884.
Database 'DB_CATA_ST4' running the upgrade step from version 884 to version 885.
Database 'DB_CATA_ST4' running the upgrade step from version 885 to version 886.
Database 'DB_CATA_ST4' running the upgrade step from version 886 to version 887.
Database 'DB_CATA_ST4' running the upgrade step from version 887 to version 888.
Database 'DB_CATA_ST4' running the upgrade step from version 888 to version 889.
Database 'DB_CATA_ST4' running the upgrade step from version 889 to version 890.
Database 'DB_CATA_ST4' running the upgrade step from version 890 to version 891.
Database 'DB_CATA_ST4' running the upgrade step from version 891 to version 892.
Database 'DB_CATA_ST4' running the upgrade step from version 892 to version 893.
Database 'DB_CATA_ST4' running the upgrade step from version 893 to version 894.
Database 'DB_CATA_ST4' running the upgrade step from version 894 to version 895.
Database 'DB_CATA_ST4' running the upgrade step from version 895 to version 896.
Database 'DB_CATA_ST4' running the upgrade step from version 896 to version 897.
Database 'DB_CATA_ST4' running the upgrade step from version 897 to version 898.
Database 'DB_CATA_ST4' running the upgrade step from version 898 to version 899.
Database 'DB_CATA_ST4' running the upgrade step from version 899 to version 900.
Database 'DB_CATA_ST4' running the upgrade step from version 900 to version 901.
Database 'DB_CATA_ST4' running the upgrade step from version 901 to version 902.
Database 'DB_CATA_ST4' running the upgrade step from version 902 to version 903.
Database 'DB_CATA_ST4' running the upgrade step from version 903 to version 904.
Database 'DB_CATA_ST4' running the upgrade step from version 904 to version 905.
Database 'DB_CATA_ST4' running the upgrade step from version 905 to version 906.
Database 'DB_CATA_ST4' running the upgrade step from version 906 to version 907.
Database 'DB_CATA_ST4' running the upgrade step from version 907 to version 908.
Database 'DB_CATA_ST4' running the upgrade step from version 908 to version 909.
Database 'DB_CATA_ST4' running the upgrade step from version 909 to version 910.
Database 'DB_CATA_ST4' running the upgrade step from version 910 to version 911.
Database 'DB_CATA_ST4' running the upgrade step from version 911 to version 912.
Database 'DB_CATA_ST4' running the upgrade step from version 912 to version 913.
Database 'DB_CATA_ST4' running the upgrade step from version 913 to version 914.
Database 'DB_CATA_ST4' running the upgrade step from version 914 to version 915.
Database 'DB_CATA_ST4' running the upgrade step from version 915 to version 916.
Database 'DB_CATA_ST4' running the upgrade step from version 916 to version 917.
Database 'DB_CATA_ST4' running the upgrade step from version 917 to version 918.
Database 'DB_CATA_ST4' running the upgrade step from version 918 to version 919.
Database 'DB_CATA_ST4' running the upgrade step from version 919 to version 920.
Database 'DB_CATA_ST4' running the upgrade step from version 920 to version 921.
Database 'DB_CATA_ST4' running the upgrade step from version 921 to version 922.
Database 'DB_CATA_ST4' running the upgrade step from version 922 to version 923.
Database 'DB_CATA_ST4' running the upgrade step from version 923 to version 924.
Database 'DB_CATA_ST4' running the upgrade step from version 924 to version 925.
Database 'DB_CATA_ST4' running the upgrade step from version 925 to version 926.
Database 'DB_CATA_ST4' running the upgrade step from version 926 to version 927.
Database 'DB_CATA_ST4' running the upgrade step from version 927 to version 928.
Database 'DB_CATA_ST4' running the upgrade step from version 928 to version 929.
Database 'DB_CATA_ST4' running the upgrade step from version 929 to version 930.
Database 'DB_CATA_ST4' running the upgrade step from version 930 to version 931.
Database 'DB_CATA_ST4' running the upgrade step from version 931 to version 932.
Database 'DB_CATA_ST4' running the upgrade step from version 932 to version 933.
Database 'DB_CATA_ST4' running the upgrade step from version 933 to version 934.
Database 'DB_CATA_ST4' running the upgrade step from version 934 to version 935.
Database 'DB_CATA_ST4' running the upgrade step from version 935 to version 936.
Database 'DB_CATA_ST4' running the upgrade step from version 936 to version 937.
Database 'DB_CATA_ST4' running the upgrade step from version 937 to version 938.
Database 'DB_CATA_ST4' running the upgrade step from version 938 to version 939.
Database 'DB_CATA_ST4' running the upgrade step from version 939 to version 940.
Database 'DB_CATA_ST4' running the upgrade step from version 940 to version 941.
Database 'DB_CATA_ST4' running the upgrade step from version 941 to version 942.
Database 'DB_CATA_ST4' running the upgrade step from version 942 to version 943.
Database 'DB_CATA_ST4' running the upgrade step from version 943 to version 944.
Database 'DB_CATA_ST4' running the upgrade step from version 944 to version 945.
Database 'DB_CATA_ST4' running the upgrade step from version 945 to version 946.
Database 'DB_CATA_ST4' running the upgrade step from version 946 to version 947.
Database 'DB_CATA_ST4' running the upgrade step from version 947 to version 948.
Database 'DB_CATA_ST4' running the upgrade step from version 948 to version 949.
Database 'DB_CATA_ST4' running the upgrade step from version 949 to version 950.
Database 'DB_CATA_ST4' running the upgrade step from version 950 to version 951.
Database 'DB_CATA_ST4' running the upgrade step from version 951 to version 952.
Database 'DB_CATA_ST4' running the upgrade step from version 952 to version 953.
Database 'DB_CATA_ST4' running the upgrade step from version 953 to version 954.
Database 'DB_CATA_ST4' running the upgrade step from version 954 to version 955.
Database 'DB_CATA_ST4' running the upgrade step from version 955 to version 956.
Database 'DB_CATA_ST4' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 2074 pages in 0.153 seconds (105.854 MB/sec).
* run end
 
* restore: server[CNACLTWCPD403S]>>[CNSISTWSQL100], database[DB_CATA_EXT]>>[DB_CATA_EXT_ST4]

(2 rows affected)
* run sql:
restore database DB_CATA_EXT_ST4
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\CNACLTWCPD403S_DB_CATA_EXT_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'DB_CATA_EXT_Data' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_CATA_EXT_ST4.mdf',
     move 'DB_CATA_EXT_Log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_CATA_EXT_ST4_log.ldf',
     file = 1,
     --medianame = 'CNACLTWCPD403S_DB_CATA_EXT_full_backup_2025_04_09_16_02_28',
     stats = 20;
20 percent processed.
40 percent processed.
60 percent processed.
80 percent processed.
100 percent processed.
Processed 18040 pages for database 'DB_CATA_EXT_ST4', file 'DB_CATA_EXT_Data' on file 1.
Processed 3 pages for database 'DB_CATA_EXT_ST4', file 'DB_CATA_EXT_Log' on file 1.
Converting database 'DB_CATA_EXT_ST4' from version 852 to the current version 957.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 852 to version 853.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 853 to version 854.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 854 to version 855.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 855 to version 856.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 856 to version 857.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 857 to version 858.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 858 to version 859.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 859 to version 860.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 860 to version 861.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 861 to version 862.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 862 to version 863.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 863 to version 864.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 864 to version 865.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 865 to version 866.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 866 to version 867.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 867 to version 868.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 868 to version 869.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 869 to version 875.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 875 to version 876.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 876 to version 877.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 877 to version 878.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 878 to version 879.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 879 to version 880.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 880 to version 881.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 881 to version 882.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 882 to version 883.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 883 to version 884.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 884 to version 885.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 885 to version 886.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 886 to version 887.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 887 to version 888.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 888 to version 889.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 889 to version 890.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 890 to version 891.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 891 to version 892.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 892 to version 893.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 893 to version 894.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 894 to version 895.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 895 to version 896.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 896 to version 897.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 897 to version 898.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 898 to version 899.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 899 to version 900.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 900 to version 901.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 901 to version 902.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 902 to version 903.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 903 to version 904.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 904 to version 905.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 905 to version 906.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 906 to version 907.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 907 to version 908.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 908 to version 909.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 909 to version 910.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 910 to version 911.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 911 to version 912.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 912 to version 913.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 913 to version 914.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 914 to version 915.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 915 to version 916.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 916 to version 917.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 917 to version 918.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 918 to version 919.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 919 to version 920.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 920 to version 921.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 921 to version 922.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 922 to version 923.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 923 to version 924.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 924 to version 925.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 925 to version 926.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 926 to version 927.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 927 to version 928.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 928 to version 929.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 929 to version 930.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 930 to version 931.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 931 to version 932.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 932 to version 933.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 933 to version 934.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 934 to version 935.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 935 to version 936.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 936 to version 937.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 937 to version 938.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 938 to version 939.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 939 to version 940.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 940 to version 941.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 941 to version 942.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 942 to version 943.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 943 to version 944.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 944 to version 945.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 945 to version 946.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 946 to version 947.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 947 to version 948.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 948 to version 949.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 949 to version 950.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 950 to version 951.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 951 to version 952.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 952 to version 953.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 953 to version 954.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 954 to version 955.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 955 to version 956.
Database 'DB_CATA_EXT_ST4' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 18043 pages in 1.314 seconds (107.275 MB/sec).
* run end
 
* restore: server[CNACLTWCPD403S]>>[CNSISTWSQL100], database[DB_DC1]>>[DB_DC1_ST4]

(2 rows affected)
* run sql:
restore database DB_DC1_ST4
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\CNACLTWCPD403S_DB_DC1_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'DB_DC1_Data' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_DC1_ST4.mdf',
     move 'DB_DC1_log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_DC1_ST4_log.ldf',
     file = 1,
     --medianame = 'CNACLTWCPD403S_DB_DC1_full_backup_2025_04_09_16_02_28',
     stats = 20;
20 percent processed.
40 percent processed.
60 percent processed.
80 percent processed.
100 percent processed.
Processed 190208 pages for database 'DB_DC1_ST4', file 'DB_DC1_Data' on file 1.
Processed 2 pages for database 'DB_DC1_ST4', file 'DB_DC1_log' on file 1.
Converting database 'DB_DC1_ST4' from version 852 to the current version 957.
Database 'DB_DC1_ST4' running the upgrade step from version 852 to version 853.
Database 'DB_DC1_ST4' running the upgrade step from version 853 to version 854.
Database 'DB_DC1_ST4' running the upgrade step from version 854 to version 855.
Database 'DB_DC1_ST4' running the upgrade step from version 855 to version 856.
Database 'DB_DC1_ST4' running the upgrade step from version 856 to version 857.
Database 'DB_DC1_ST4' running the upgrade step from version 857 to version 858.
Database 'DB_DC1_ST4' running the upgrade step from version 858 to version 859.
Database 'DB_DC1_ST4' running the upgrade step from version 859 to version 860.
Database 'DB_DC1_ST4' running the upgrade step from version 860 to version 861.
Database 'DB_DC1_ST4' running the upgrade step from version 861 to version 862.
Database 'DB_DC1_ST4' running the upgrade step from version 862 to version 863.
Database 'DB_DC1_ST4' running the upgrade step from version 863 to version 864.
Database 'DB_DC1_ST4' running the upgrade step from version 864 to version 865.
Database 'DB_DC1_ST4' running the upgrade step from version 865 to version 866.
Database 'DB_DC1_ST4' running the upgrade step from version 866 to version 867.
Database 'DB_DC1_ST4' running the upgrade step from version 867 to version 868.
Database 'DB_DC1_ST4' running the upgrade step from version 868 to version 869.
Database 'DB_DC1_ST4' running the upgrade step from version 869 to version 875.
Database 'DB_DC1_ST4' running the upgrade step from version 875 to version 876.
Database 'DB_DC1_ST4' running the upgrade step from version 876 to version 877.
Database 'DB_DC1_ST4' running the upgrade step from version 877 to version 878.
Database 'DB_DC1_ST4' running the upgrade step from version 878 to version 879.
Database 'DB_DC1_ST4' running the upgrade step from version 879 to version 880.
Database 'DB_DC1_ST4' running the upgrade step from version 880 to version 881.
Database 'DB_DC1_ST4' running the upgrade step from version 881 to version 882.
Database 'DB_DC1_ST4' running the upgrade step from version 882 to version 883.
Database 'DB_DC1_ST4' running the upgrade step from version 883 to version 884.
Database 'DB_DC1_ST4' running the upgrade step from version 884 to version 885.
Database 'DB_DC1_ST4' running the upgrade step from version 885 to version 886.
Database 'DB_DC1_ST4' running the upgrade step from version 886 to version 887.
Database 'DB_DC1_ST4' running the upgrade step from version 887 to version 888.
Database 'DB_DC1_ST4' running the upgrade step from version 888 to version 889.
Database 'DB_DC1_ST4' running the upgrade step from version 889 to version 890.
Database 'DB_DC1_ST4' running the upgrade step from version 890 to version 891.
Database 'DB_DC1_ST4' running the upgrade step from version 891 to version 892.
Database 'DB_DC1_ST4' running the upgrade step from version 892 to version 893.
Database 'DB_DC1_ST4' running the upgrade step from version 893 to version 894.
Database 'DB_DC1_ST4' running the upgrade step from version 894 to version 895.
Database 'DB_DC1_ST4' running the upgrade step from version 895 to version 896.
Database 'DB_DC1_ST4' running the upgrade step from version 896 to version 897.
Database 'DB_DC1_ST4' running the upgrade step from version 897 to version 898.
Database 'DB_DC1_ST4' running the upgrade step from version 898 to version 899.
Database 'DB_DC1_ST4' running the upgrade step from version 899 to version 900.
Database 'DB_DC1_ST4' running the upgrade step from version 900 to version 901.
Database 'DB_DC1_ST4' running the upgrade step from version 901 to version 902.
Database 'DB_DC1_ST4' running the upgrade step from version 902 to version 903.
Database 'DB_DC1_ST4' running the upgrade step from version 903 to version 904.
Database 'DB_DC1_ST4' running the upgrade step from version 904 to version 905.
Database 'DB_DC1_ST4' running the upgrade step from version 905 to version 906.
Database 'DB_DC1_ST4' running the upgrade step from version 906 to version 907.
Database 'DB_DC1_ST4' running the upgrade step from version 907 to version 908.
Database 'DB_DC1_ST4' running the upgrade step from version 908 to version 909.
Database 'DB_DC1_ST4' running the upgrade step from version 909 to version 910.
Database 'DB_DC1_ST4' running the upgrade step from version 910 to version 911.
Database 'DB_DC1_ST4' running the upgrade step from version 911 to version 912.
Database 'DB_DC1_ST4' running the upgrade step from version 912 to version 913.
Database 'DB_DC1_ST4' running the upgrade step from version 913 to version 914.
Database 'DB_DC1_ST4' running the upgrade step from version 914 to version 915.
Database 'DB_DC1_ST4' running the upgrade step from version 915 to version 916.
Database 'DB_DC1_ST4' running the upgrade step from version 916 to version 917.
Database 'DB_DC1_ST4' running the upgrade step from version 917 to version 918.
Database 'DB_DC1_ST4' running the upgrade step from version 918 to version 919.
Database 'DB_DC1_ST4' running the upgrade step from version 919 to version 920.
Database 'DB_DC1_ST4' running the upgrade step from version 920 to version 921.
Database 'DB_DC1_ST4' running the upgrade step from version 921 to version 922.
Database 'DB_DC1_ST4' running the upgrade step from version 922 to version 923.
Database 'DB_DC1_ST4' running the upgrade step from version 923 to version 924.
Database 'DB_DC1_ST4' running the upgrade step from version 924 to version 925.
Database 'DB_DC1_ST4' running the upgrade step from version 925 to version 926.
Database 'DB_DC1_ST4' running the upgrade step from version 926 to version 927.
Database 'DB_DC1_ST4' running the upgrade step from version 927 to version 928.
Database 'DB_DC1_ST4' running the upgrade step from version 928 to version 929.
Database 'DB_DC1_ST4' running the upgrade step from version 929 to version 930.
Database 'DB_DC1_ST4' running the upgrade step from version 930 to version 931.
Database 'DB_DC1_ST4' running the upgrade step from version 931 to version 932.
Database 'DB_DC1_ST4' running the upgrade step from version 932 to version 933.
Database 'DB_DC1_ST4' running the upgrade step from version 933 to version 934.
Database 'DB_DC1_ST4' running the upgrade step from version 934 to version 935.
Database 'DB_DC1_ST4' running the upgrade step from version 935 to version 936.
Database 'DB_DC1_ST4' running the upgrade step from version 936 to version 937.
Database 'DB_DC1_ST4' running the upgrade step from version 937 to version 938.
Database 'DB_DC1_ST4' running the upgrade step from version 938 to version 939.
Database 'DB_DC1_ST4' running the upgrade step from version 939 to version 940.
Database 'DB_DC1_ST4' running the upgrade step from version 940 to version 941.
Database 'DB_DC1_ST4' running the upgrade step from version 941 to version 942.
Database 'DB_DC1_ST4' running the upgrade step from version 942 to version 943.
Database 'DB_DC1_ST4' running the upgrade step from version 943 to version 944.
Database 'DB_DC1_ST4' running the upgrade step from version 944 to version 945.
Database 'DB_DC1_ST4' running the upgrade step from version 945 to version 946.
Database 'DB_DC1_ST4' running the upgrade step from version 946 to version 947.
Database 'DB_DC1_ST4' running the upgrade step from version 947 to version 948.
Database 'DB_DC1_ST4' running the upgrade step from version 948 to version 949.
Database 'DB_DC1_ST4' running the upgrade step from version 949 to version 950.
Database 'DB_DC1_ST4' running the upgrade step from version 950 to version 951.
Database 'DB_DC1_ST4' running the upgrade step from version 951 to version 952.
Database 'DB_DC1_ST4' running the upgrade step from version 952 to version 953.
Database 'DB_DC1_ST4' running the upgrade step from version 953 to version 954.
Database 'DB_DC1_ST4' running the upgrade step from version 954 to version 955.
Database 'DB_DC1_ST4' running the upgrade step from version 955 to version 956.
Database 'DB_DC1_ST4' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 190210 pages in 13.554 seconds (109.636 MB/sec).
* run end
 
* restore: server[CNACLTWCPD403S]>>[CNSISTWSQL100], database[DB_HFV_ST4]>>[DB_HFV_ST1]

(2 rows affected)
* run sql:
restore database DB_HFV_ST1
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\CNACLTWCPD403S_DB_HFV_ST4_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'db_hfv_st4' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_HFV_ST1.mdf',
     move 'db_hfv_st4_log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_HFV_ST1_log.ldf',
     file = 1,
     --medianame = 'CNACLTWCPD403S_DB_HFV_ST4_full_backup_2025_04_09_16_02_28',
     stats = 20;
20 percent processed.
40 percent processed.
61 percent processed.
81 percent processed.
100 percent processed.
Processed 5616 pages for database 'DB_HFV_ST1', file 'db_hfv_st4' on file 1.
Processed 7 pages for database 'DB_HFV_ST1', file 'db_hfv_st4_log' on file 1.
Converting database 'DB_HFV_ST1' from version 852 to the current version 957.
Database 'DB_HFV_ST1' running the upgrade step from version 852 to version 853.
Database 'DB_HFV_ST1' running the upgrade step from version 853 to version 854.
Database 'DB_HFV_ST1' running the upgrade step from version 854 to version 855.
Database 'DB_HFV_ST1' running the upgrade step from version 855 to version 856.
Database 'DB_HFV_ST1' running the upgrade step from version 856 to version 857.
Database 'DB_HFV_ST1' running the upgrade step from version 857 to version 858.
Database 'DB_HFV_ST1' running the upgrade step from version 858 to version 859.
Database 'DB_HFV_ST1' running the upgrade step from version 859 to version 860.
Database 'DB_HFV_ST1' running the upgrade step from version 860 to version 861.
Database 'DB_HFV_ST1' running the upgrade step from version 861 to version 862.
Database 'DB_HFV_ST1' running the upgrade step from version 862 to version 863.
Database 'DB_HFV_ST1' running the upgrade step from version 863 to version 864.
Database 'DB_HFV_ST1' running the upgrade step from version 864 to version 865.
Database 'DB_HFV_ST1' running the upgrade step from version 865 to version 866.
Database 'DB_HFV_ST1' running the upgrade step from version 866 to version 867.
Database 'DB_HFV_ST1' running the upgrade step from version 867 to version 868.
Database 'DB_HFV_ST1' running the upgrade step from version 868 to version 869.
Database 'DB_HFV_ST1' running the upgrade step from version 869 to version 875.
Database 'DB_HFV_ST1' running the upgrade step from version 875 to version 876.
Database 'DB_HFV_ST1' running the upgrade step from version 876 to version 877.
Database 'DB_HFV_ST1' running the upgrade step from version 877 to version 878.
Database 'DB_HFV_ST1' running the upgrade step from version 878 to version 879.
Database 'DB_HFV_ST1' running the upgrade step from version 879 to version 880.
Database 'DB_HFV_ST1' running the upgrade step from version 880 to version 881.
Database 'DB_HFV_ST1' running the upgrade step from version 881 to version 882.
Database 'DB_HFV_ST1' running the upgrade step from version 882 to version 883.
Database 'DB_HFV_ST1' running the upgrade step from version 883 to version 884.
Database 'DB_HFV_ST1' running the upgrade step from version 884 to version 885.
Database 'DB_HFV_ST1' running the upgrade step from version 885 to version 886.
Database 'DB_HFV_ST1' running the upgrade step from version 886 to version 887.
Database 'DB_HFV_ST1' running the upgrade step from version 887 to version 888.
Database 'DB_HFV_ST1' running the upgrade step from version 888 to version 889.
Database 'DB_HFV_ST1' running the upgrade step from version 889 to version 890.
Database 'DB_HFV_ST1' running the upgrade step from version 890 to version 891.
Database 'DB_HFV_ST1' running the upgrade step from version 891 to version 892.
Database 'DB_HFV_ST1' running the upgrade step from version 892 to version 893.
Database 'DB_HFV_ST1' running the upgrade step from version 893 to version 894.
Database 'DB_HFV_ST1' running the upgrade step from version 894 to version 895.
Database 'DB_HFV_ST1' running the upgrade step from version 895 to version 896.
Database 'DB_HFV_ST1' running the upgrade step from version 896 to version 897.
Database 'DB_HFV_ST1' running the upgrade step from version 897 to version 898.
Database 'DB_HFV_ST1' running the upgrade step from version 898 to version 899.
Database 'DB_HFV_ST1' running the upgrade step from version 899 to version 900.
Database 'DB_HFV_ST1' running the upgrade step from version 900 to version 901.
Database 'DB_HFV_ST1' running the upgrade step from version 901 to version 902.
Database 'DB_HFV_ST1' running the upgrade step from version 902 to version 903.
Database 'DB_HFV_ST1' running the upgrade step from version 903 to version 904.
Database 'DB_HFV_ST1' running the upgrade step from version 904 to version 905.
Database 'DB_HFV_ST1' running the upgrade step from version 905 to version 906.
Database 'DB_HFV_ST1' running the upgrade step from version 906 to version 907.
Database 'DB_HFV_ST1' running the upgrade step from version 907 to version 908.
Database 'DB_HFV_ST1' running the upgrade step from version 908 to version 909.
Database 'DB_HFV_ST1' running the upgrade step from version 909 to version 910.
Database 'DB_HFV_ST1' running the upgrade step from version 910 to version 911.
Database 'DB_HFV_ST1' running the upgrade step from version 911 to version 912.
Database 'DB_HFV_ST1' running the upgrade step from version 912 to version 913.
Database 'DB_HFV_ST1' running the upgrade step from version 913 to version 914.
Database 'DB_HFV_ST1' running the upgrade step from version 914 to version 915.
Database 'DB_HFV_ST1' running the upgrade step from version 915 to version 916.
Database 'DB_HFV_ST1' running the upgrade step from version 916 to version 917.
Database 'DB_HFV_ST1' running the upgrade step from version 917 to version 918.
Database 'DB_HFV_ST1' running the upgrade step from version 918 to version 919.
Database 'DB_HFV_ST1' running the upgrade step from version 919 to version 920.
Database 'DB_HFV_ST1' running the upgrade step from version 920 to version 921.
Database 'DB_HFV_ST1' running the upgrade step from version 921 to version 922.
Database 'DB_HFV_ST1' running the upgrade step from version 922 to version 923.
Database 'DB_HFV_ST1' running the upgrade step from version 923 to version 924.
Database 'DB_HFV_ST1' running the upgrade step from version 924 to version 925.
Database 'DB_HFV_ST1' running the upgrade step from version 925 to version 926.
Database 'DB_HFV_ST1' running the upgrade step from version 926 to version 927.
Database 'DB_HFV_ST1' running the upgrade step from version 927 to version 928.
Database 'DB_HFV_ST1' running the upgrade step from version 928 to version 929.
Database 'DB_HFV_ST1' running the upgrade step from version 929 to version 930.
Database 'DB_HFV_ST1' running the upgrade step from version 930 to version 931.
Database 'DB_HFV_ST1' running the upgrade step from version 931 to version 932.
Database 'DB_HFV_ST1' running the upgrade step from version 932 to version 933.
Database 'DB_HFV_ST1' running the upgrade step from version 933 to version 934.
Database 'DB_HFV_ST1' running the upgrade step from version 934 to version 935.
Database 'DB_HFV_ST1' running the upgrade step from version 935 to version 936.
Database 'DB_HFV_ST1' running the upgrade step from version 936 to version 937.
Database 'DB_HFV_ST1' running the upgrade step from version 937 to version 938.
Database 'DB_HFV_ST1' running the upgrade step from version 938 to version 939.
Database 'DB_HFV_ST1' running the upgrade step from version 939 to version 940.
Database 'DB_HFV_ST1' running the upgrade step from version 940 to version 941.
Database 'DB_HFV_ST1' running the upgrade step from version 941 to version 942.
Database 'DB_HFV_ST1' running the upgrade step from version 942 to version 943.
Database 'DB_HFV_ST1' running the upgrade step from version 943 to version 944.
Database 'DB_HFV_ST1' running the upgrade step from version 944 to version 945.
Database 'DB_HFV_ST1' running the upgrade step from version 945 to version 946.
Database 'DB_HFV_ST1' running the upgrade step from version 946 to version 947.
Database 'DB_HFV_ST1' running the upgrade step from version 947 to version 948.
Database 'DB_HFV_ST1' running the upgrade step from version 948 to version 949.
Database 'DB_HFV_ST1' running the upgrade step from version 949 to version 950.
Database 'DB_HFV_ST1' running the upgrade step from version 950 to version 951.
Database 'DB_HFV_ST1' running the upgrade step from version 951 to version 952.
Database 'DB_HFV_ST1' running the upgrade step from version 952 to version 953.
Database 'DB_HFV_ST1' running the upgrade step from version 953 to version 954.
Database 'DB_HFV_ST1' running the upgrade step from version 954 to version 955.
Database 'DB_HFV_ST1' running the upgrade step from version 955 to version 956.
Database 'DB_HFV_ST1' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 5623 pages in 1.421 seconds (30.912 MB/sec).
* run end
 
* restore: server[CNACLTWCPD403S]>>[CNSISTWSQL100], database[DB_HFV_ST4]>>[DB_HFV_ST2]

(2 rows affected)
* run sql:
restore database DB_HFV_ST2
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\CNACLTWCPD403S_DB_HFV_ST4_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'db_hfv_st4' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_HFV_ST2.mdf',
     move 'db_hfv_st4_log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_HFV_ST2_log.ldf',
     file = 1,
     --medianame = 'CNACLTWCPD403S_DB_HFV_ST4_full_backup_2025_04_09_16_02_28',
     stats = 20;
20 percent processed.
40 percent processed.
61 percent processed.
81 percent processed.
100 percent processed.
Processed 5616 pages for database 'DB_HFV_ST2', file 'db_hfv_st4' on file 1.
Processed 7 pages for database 'DB_HFV_ST2', file 'db_hfv_st4_log' on file 1.
Converting database 'DB_HFV_ST2' from version 852 to the current version 957.
Database 'DB_HFV_ST2' running the upgrade step from version 852 to version 853.
Database 'DB_HFV_ST2' running the upgrade step from version 853 to version 854.
Database 'DB_HFV_ST2' running the upgrade step from version 854 to version 855.
Database 'DB_HFV_ST2' running the upgrade step from version 855 to version 856.
Database 'DB_HFV_ST2' running the upgrade step from version 856 to version 857.
Database 'DB_HFV_ST2' running the upgrade step from version 857 to version 858.
Database 'DB_HFV_ST2' running the upgrade step from version 858 to version 859.
Database 'DB_HFV_ST2' running the upgrade step from version 859 to version 860.
Database 'DB_HFV_ST2' running the upgrade step from version 860 to version 861.
Database 'DB_HFV_ST2' running the upgrade step from version 861 to version 862.
Database 'DB_HFV_ST2' running the upgrade step from version 862 to version 863.
Database 'DB_HFV_ST2' running the upgrade step from version 863 to version 864.
Database 'DB_HFV_ST2' running the upgrade step from version 864 to version 865.
Database 'DB_HFV_ST2' running the upgrade step from version 865 to version 866.
Database 'DB_HFV_ST2' running the upgrade step from version 866 to version 867.
Database 'DB_HFV_ST2' running the upgrade step from version 867 to version 868.
Database 'DB_HFV_ST2' running the upgrade step from version 868 to version 869.
Database 'DB_HFV_ST2' running the upgrade step from version 869 to version 875.
Database 'DB_HFV_ST2' running the upgrade step from version 875 to version 876.
Database 'DB_HFV_ST2' running the upgrade step from version 876 to version 877.
Database 'DB_HFV_ST2' running the upgrade step from version 877 to version 878.
Database 'DB_HFV_ST2' running the upgrade step from version 878 to version 879.
Database 'DB_HFV_ST2' running the upgrade step from version 879 to version 880.
Database 'DB_HFV_ST2' running the upgrade step from version 880 to version 881.
Database 'DB_HFV_ST2' running the upgrade step from version 881 to version 882.
Database 'DB_HFV_ST2' running the upgrade step from version 882 to version 883.
Database 'DB_HFV_ST2' running the upgrade step from version 883 to version 884.
Database 'DB_HFV_ST2' running the upgrade step from version 884 to version 885.
Database 'DB_HFV_ST2' running the upgrade step from version 885 to version 886.
Database 'DB_HFV_ST2' running the upgrade step from version 886 to version 887.
Database 'DB_HFV_ST2' running the upgrade step from version 887 to version 888.
Database 'DB_HFV_ST2' running the upgrade step from version 888 to version 889.
Database 'DB_HFV_ST2' running the upgrade step from version 889 to version 890.
Database 'DB_HFV_ST2' running the upgrade step from version 890 to version 891.
Database 'DB_HFV_ST2' running the upgrade step from version 891 to version 892.
Database 'DB_HFV_ST2' running the upgrade step from version 892 to version 893.
Database 'DB_HFV_ST2' running the upgrade step from version 893 to version 894.
Database 'DB_HFV_ST2' running the upgrade step from version 894 to version 895.
Database 'DB_HFV_ST2' running the upgrade step from version 895 to version 896.
Database 'DB_HFV_ST2' running the upgrade step from version 896 to version 897.
Database 'DB_HFV_ST2' running the upgrade step from version 897 to version 898.
Database 'DB_HFV_ST2' running the upgrade step from version 898 to version 899.
Database 'DB_HFV_ST2' running the upgrade step from version 899 to version 900.
Database 'DB_HFV_ST2' running the upgrade step from version 900 to version 901.
Database 'DB_HFV_ST2' running the upgrade step from version 901 to version 902.
Database 'DB_HFV_ST2' running the upgrade step from version 902 to version 903.
Database 'DB_HFV_ST2' running the upgrade step from version 903 to version 904.
Database 'DB_HFV_ST2' running the upgrade step from version 904 to version 905.
Database 'DB_HFV_ST2' running the upgrade step from version 905 to version 906.
Database 'DB_HFV_ST2' running the upgrade step from version 906 to version 907.
Database 'DB_HFV_ST2' running the upgrade step from version 907 to version 908.
Database 'DB_HFV_ST2' running the upgrade step from version 908 to version 909.
Database 'DB_HFV_ST2' running the upgrade step from version 909 to version 910.
Database 'DB_HFV_ST2' running the upgrade step from version 910 to version 911.
Database 'DB_HFV_ST2' running the upgrade step from version 911 to version 912.
Database 'DB_HFV_ST2' running the upgrade step from version 912 to version 913.
Database 'DB_HFV_ST2' running the upgrade step from version 913 to version 914.
Database 'DB_HFV_ST2' running the upgrade step from version 914 to version 915.
Database 'DB_HFV_ST2' running the upgrade step from version 915 to version 916.
Database 'DB_HFV_ST2' running the upgrade step from version 916 to version 917.
Database 'DB_HFV_ST2' running the upgrade step from version 917 to version 918.
Database 'DB_HFV_ST2' running the upgrade step from version 918 to version 919.
Database 'DB_HFV_ST2' running the upgrade step from version 919 to version 920.
Database 'DB_HFV_ST2' running the upgrade step from version 920 to version 921.
Database 'DB_HFV_ST2' running the upgrade step from version 921 to version 922.
Database 'DB_HFV_ST2' running the upgrade step from version 922 to version 923.
Database 'DB_HFV_ST2' running the upgrade step from version 923 to version 924.
Database 'DB_HFV_ST2' running the upgrade step from version 924 to version 925.
Database 'DB_HFV_ST2' running the upgrade step from version 925 to version 926.
Database 'DB_HFV_ST2' running the upgrade step from version 926 to version 927.
Database 'DB_HFV_ST2' running the upgrade step from version 927 to version 928.
Database 'DB_HFV_ST2' running the upgrade step from version 928 to version 929.
Database 'DB_HFV_ST2' running the upgrade step from version 929 to version 930.
Database 'DB_HFV_ST2' running the upgrade step from version 930 to version 931.
Database 'DB_HFV_ST2' running the upgrade step from version 931 to version 932.
Database 'DB_HFV_ST2' running the upgrade step from version 932 to version 933.
Database 'DB_HFV_ST2' running the upgrade step from version 933 to version 934.
Database 'DB_HFV_ST2' running the upgrade step from version 934 to version 935.
Database 'DB_HFV_ST2' running the upgrade step from version 935 to version 936.
Database 'DB_HFV_ST2' running the upgrade step from version 936 to version 937.
Database 'DB_HFV_ST2' running the upgrade step from version 937 to version 938.
Database 'DB_HFV_ST2' running the upgrade step from version 938 to version 939.
Database 'DB_HFV_ST2' running the upgrade step from version 939 to version 940.
Database 'DB_HFV_ST2' running the upgrade step from version 940 to version 941.
Database 'DB_HFV_ST2' running the upgrade step from version 941 to version 942.
Database 'DB_HFV_ST2' running the upgrade step from version 942 to version 943.
Database 'DB_HFV_ST2' running the upgrade step from version 943 to version 944.
Database 'DB_HFV_ST2' running the upgrade step from version 944 to version 945.
Database 'DB_HFV_ST2' running the upgrade step from version 945 to version 946.
Database 'DB_HFV_ST2' running the upgrade step from version 946 to version 947.
Database 'DB_HFV_ST2' running the upgrade step from version 947 to version 948.
Database 'DB_HFV_ST2' running the upgrade step from version 948 to version 949.
Database 'DB_HFV_ST2' running the upgrade step from version 949 to version 950.
Database 'DB_HFV_ST2' running the upgrade step from version 950 to version 951.
Database 'DB_HFV_ST2' running the upgrade step from version 951 to version 952.
Database 'DB_HFV_ST2' running the upgrade step from version 952 to version 953.
Database 'DB_HFV_ST2' running the upgrade step from version 953 to version 954.
Database 'DB_HFV_ST2' running the upgrade step from version 954 to version 955.
Database 'DB_HFV_ST2' running the upgrade step from version 955 to version 956.
Database 'DB_HFV_ST2' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 5623 pages in 1.366 seconds (32.157 MB/sec).
* run end
 
* restore: server[CNACLTWCPD403S]>>[CNSISTWSQL100], database[DB_HFV_ST4]>>[DB_HFV_ST3]

(2 rows affected)
* run sql:
restore database DB_HFV_ST3
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\CNACLTWCPD403S_DB_HFV_ST4_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'db_hfv_st4' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_HFV_ST3.mdf',
     move 'db_hfv_st4_log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_HFV_ST3_log.ldf',
     file = 1,
     --medianame = 'CNACLTWCPD403S_DB_HFV_ST4_full_backup_2025_04_09_16_02_28',
     stats = 20;
20 percent processed.
40 percent processed.
61 percent processed.
81 percent processed.
100 percent processed.
Processed 5616 pages for database 'DB_HFV_ST3', file 'db_hfv_st4' on file 1.
Processed 7 pages for database 'DB_HFV_ST3', file 'db_hfv_st4_log' on file 1.
Converting database 'DB_HFV_ST3' from version 852 to the current version 957.
Database 'DB_HFV_ST3' running the upgrade step from version 852 to version 853.
Database 'DB_HFV_ST3' running the upgrade step from version 853 to version 854.
Database 'DB_HFV_ST3' running the upgrade step from version 854 to version 855.
Database 'DB_HFV_ST3' running the upgrade step from version 855 to version 856.
Database 'DB_HFV_ST3' running the upgrade step from version 856 to version 857.
Database 'DB_HFV_ST3' running the upgrade step from version 857 to version 858.
Database 'DB_HFV_ST3' running the upgrade step from version 858 to version 859.
Database 'DB_HFV_ST3' running the upgrade step from version 859 to version 860.
Database 'DB_HFV_ST3' running the upgrade step from version 860 to version 861.
Database 'DB_HFV_ST3' running the upgrade step from version 861 to version 862.
Database 'DB_HFV_ST3' running the upgrade step from version 862 to version 863.
Database 'DB_HFV_ST3' running the upgrade step from version 863 to version 864.
Database 'DB_HFV_ST3' running the upgrade step from version 864 to version 865.
Database 'DB_HFV_ST3' running the upgrade step from version 865 to version 866.
Database 'DB_HFV_ST3' running the upgrade step from version 866 to version 867.
Database 'DB_HFV_ST3' running the upgrade step from version 867 to version 868.
Database 'DB_HFV_ST3' running the upgrade step from version 868 to version 869.
Database 'DB_HFV_ST3' running the upgrade step from version 869 to version 875.
Database 'DB_HFV_ST3' running the upgrade step from version 875 to version 876.
Database 'DB_HFV_ST3' running the upgrade step from version 876 to version 877.
Database 'DB_HFV_ST3' running the upgrade step from version 877 to version 878.
Database 'DB_HFV_ST3' running the upgrade step from version 878 to version 879.
Database 'DB_HFV_ST3' running the upgrade step from version 879 to version 880.
Database 'DB_HFV_ST3' running the upgrade step from version 880 to version 881.
Database 'DB_HFV_ST3' running the upgrade step from version 881 to version 882.
Database 'DB_HFV_ST3' running the upgrade step from version 882 to version 883.
Database 'DB_HFV_ST3' running the upgrade step from version 883 to version 884.
Database 'DB_HFV_ST3' running the upgrade step from version 884 to version 885.
Database 'DB_HFV_ST3' running the upgrade step from version 885 to version 886.
Database 'DB_HFV_ST3' running the upgrade step from version 886 to version 887.
Database 'DB_HFV_ST3' running the upgrade step from version 887 to version 888.
Database 'DB_HFV_ST3' running the upgrade step from version 888 to version 889.
Database 'DB_HFV_ST3' running the upgrade step from version 889 to version 890.
Database 'DB_HFV_ST3' running the upgrade step from version 890 to version 891.
Database 'DB_HFV_ST3' running the upgrade step from version 891 to version 892.
Database 'DB_HFV_ST3' running the upgrade step from version 892 to version 893.
Database 'DB_HFV_ST3' running the upgrade step from version 893 to version 894.
Database 'DB_HFV_ST3' running the upgrade step from version 894 to version 895.
Database 'DB_HFV_ST3' running the upgrade step from version 895 to version 896.
Database 'DB_HFV_ST3' running the upgrade step from version 896 to version 897.
Database 'DB_HFV_ST3' running the upgrade step from version 897 to version 898.
Database 'DB_HFV_ST3' running the upgrade step from version 898 to version 899.
Database 'DB_HFV_ST3' running the upgrade step from version 899 to version 900.
Database 'DB_HFV_ST3' running the upgrade step from version 900 to version 901.
Database 'DB_HFV_ST3' running the upgrade step from version 901 to version 902.
Database 'DB_HFV_ST3' running the upgrade step from version 902 to version 903.
Database 'DB_HFV_ST3' running the upgrade step from version 903 to version 904.
Database 'DB_HFV_ST3' running the upgrade step from version 904 to version 905.
Database 'DB_HFV_ST3' running the upgrade step from version 905 to version 906.
Database 'DB_HFV_ST3' running the upgrade step from version 906 to version 907.
Database 'DB_HFV_ST3' running the upgrade step from version 907 to version 908.
Database 'DB_HFV_ST3' running the upgrade step from version 908 to version 909.
Database 'DB_HFV_ST3' running the upgrade step from version 909 to version 910.
Database 'DB_HFV_ST3' running the upgrade step from version 910 to version 911.
Database 'DB_HFV_ST3' running the upgrade step from version 911 to version 912.
Database 'DB_HFV_ST3' running the upgrade step from version 912 to version 913.
Database 'DB_HFV_ST3' running the upgrade step from version 913 to version 914.
Database 'DB_HFV_ST3' running the upgrade step from version 914 to version 915.
Database 'DB_HFV_ST3' running the upgrade step from version 915 to version 916.
Database 'DB_HFV_ST3' running the upgrade step from version 916 to version 917.
Database 'DB_HFV_ST3' running the upgrade step from version 917 to version 918.
Database 'DB_HFV_ST3' running the upgrade step from version 918 to version 919.
Database 'DB_HFV_ST3' running the upgrade step from version 919 to version 920.
Database 'DB_HFV_ST3' running the upgrade step from version 920 to version 921.
Database 'DB_HFV_ST3' running the upgrade step from version 921 to version 922.
Database 'DB_HFV_ST3' running the upgrade step from version 922 to version 923.
Database 'DB_HFV_ST3' running the upgrade step from version 923 to version 924.
Database 'DB_HFV_ST3' running the upgrade step from version 924 to version 925.
Database 'DB_HFV_ST3' running the upgrade step from version 925 to version 926.
Database 'DB_HFV_ST3' running the upgrade step from version 926 to version 927.
Database 'DB_HFV_ST3' running the upgrade step from version 927 to version 928.
Database 'DB_HFV_ST3' running the upgrade step from version 928 to version 929.
Database 'DB_HFV_ST3' running the upgrade step from version 929 to version 930.
Database 'DB_HFV_ST3' running the upgrade step from version 930 to version 931.
Database 'DB_HFV_ST3' running the upgrade step from version 931 to version 932.
Database 'DB_HFV_ST3' running the upgrade step from version 932 to version 933.
Database 'DB_HFV_ST3' running the upgrade step from version 933 to version 934.
Database 'DB_HFV_ST3' running the upgrade step from version 934 to version 935.
Database 'DB_HFV_ST3' running the upgrade step from version 935 to version 936.
Database 'DB_HFV_ST3' running the upgrade step from version 936 to version 937.
Database 'DB_HFV_ST3' running the upgrade step from version 937 to version 938.
Database 'DB_HFV_ST3' running the upgrade step from version 938 to version 939.
Database 'DB_HFV_ST3' running the upgrade step from version 939 to version 940.
Database 'DB_HFV_ST3' running the upgrade step from version 940 to version 941.
Database 'DB_HFV_ST3' running the upgrade step from version 941 to version 942.
Database 'DB_HFV_ST3' running the upgrade step from version 942 to version 943.
Database 'DB_HFV_ST3' running the upgrade step from version 943 to version 944.
Database 'DB_HFV_ST3' running the upgrade step from version 944 to version 945.
Database 'DB_HFV_ST3' running the upgrade step from version 945 to version 946.
Database 'DB_HFV_ST3' running the upgrade step from version 946 to version 947.
Database 'DB_HFV_ST3' running the upgrade step from version 947 to version 948.
Database 'DB_HFV_ST3' running the upgrade step from version 948 to version 949.
Database 'DB_HFV_ST3' running the upgrade step from version 949 to version 950.
Database 'DB_HFV_ST3' running the upgrade step from version 950 to version 951.
Database 'DB_HFV_ST3' running the upgrade step from version 951 to version 952.
Database 'DB_HFV_ST3' running the upgrade step from version 952 to version 953.
Database 'DB_HFV_ST3' running the upgrade step from version 953 to version 954.
Database 'DB_HFV_ST3' running the upgrade step from version 954 to version 955.
Database 'DB_HFV_ST3' running the upgrade step from version 955 to version 956.
Database 'DB_HFV_ST3' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 5623 pages in 2.068 seconds (21.241 MB/sec).
* run end
 
* restore: server[CNACLTWCPD403S]>>[CNSISTWSQL100], database[DB_HFV_ST4]>>[DB_HFV_ST4]

(2 rows affected)
* run sql:
restore database DB_HFV_ST4
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\CNACLTWCPD403S_DB_HFV_ST4_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'db_hfv_st4' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_HFV_ST4.mdf',
     move 'db_hfv_st4_log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_HFV_ST4_log.ldf',
     file = 1,
     --medianame = 'CNACLTWCPD403S_DB_HFV_ST4_full_backup_2025_04_09_16_02_28',
     stats = 20;
20 percent processed.
40 percent processed.
61 percent processed.
81 percent processed.
100 percent processed.
Processed 5616 pages for database 'DB_HFV_ST4', file 'db_hfv_st4' on file 1.
Processed 7 pages for database 'DB_HFV_ST4', file 'db_hfv_st4_log' on file 1.
Converting database 'DB_HFV_ST4' from version 852 to the current version 957.
Database 'DB_HFV_ST4' running the upgrade step from version 852 to version 853.
Database 'DB_HFV_ST4' running the upgrade step from version 853 to version 854.
Database 'DB_HFV_ST4' running the upgrade step from version 854 to version 855.
Database 'DB_HFV_ST4' running the upgrade step from version 855 to version 856.
Database 'DB_HFV_ST4' running the upgrade step from version 856 to version 857.
Database 'DB_HFV_ST4' running the upgrade step from version 857 to version 858.
Database 'DB_HFV_ST4' running the upgrade step from version 858 to version 859.
Database 'DB_HFV_ST4' running the upgrade step from version 859 to version 860.
Database 'DB_HFV_ST4' running the upgrade step from version 860 to version 861.
Database 'DB_HFV_ST4' running the upgrade step from version 861 to version 862.
Database 'DB_HFV_ST4' running the upgrade step from version 862 to version 863.
Database 'DB_HFV_ST4' running the upgrade step from version 863 to version 864.
Database 'DB_HFV_ST4' running the upgrade step from version 864 to version 865.
Database 'DB_HFV_ST4' running the upgrade step from version 865 to version 866.
Database 'DB_HFV_ST4' running the upgrade step from version 866 to version 867.
Database 'DB_HFV_ST4' running the upgrade step from version 867 to version 868.
Database 'DB_HFV_ST4' running the upgrade step from version 868 to version 869.
Database 'DB_HFV_ST4' running the upgrade step from version 869 to version 875.
Database 'DB_HFV_ST4' running the upgrade step from version 875 to version 876.
Database 'DB_HFV_ST4' running the upgrade step from version 876 to version 877.
Database 'DB_HFV_ST4' running the upgrade step from version 877 to version 878.
Database 'DB_HFV_ST4' running the upgrade step from version 878 to version 879.
Database 'DB_HFV_ST4' running the upgrade step from version 879 to version 880.
Database 'DB_HFV_ST4' running the upgrade step from version 880 to version 881.
Database 'DB_HFV_ST4' running the upgrade step from version 881 to version 882.
Database 'DB_HFV_ST4' running the upgrade step from version 882 to version 883.
Database 'DB_HFV_ST4' running the upgrade step from version 883 to version 884.
Database 'DB_HFV_ST4' running the upgrade step from version 884 to version 885.
Database 'DB_HFV_ST4' running the upgrade step from version 885 to version 886.
Database 'DB_HFV_ST4' running the upgrade step from version 886 to version 887.
Database 'DB_HFV_ST4' running the upgrade step from version 887 to version 888.
Database 'DB_HFV_ST4' running the upgrade step from version 888 to version 889.
Database 'DB_HFV_ST4' running the upgrade step from version 889 to version 890.
Database 'DB_HFV_ST4' running the upgrade step from version 890 to version 891.
Database 'DB_HFV_ST4' running the upgrade step from version 891 to version 892.
Database 'DB_HFV_ST4' running the upgrade step from version 892 to version 893.
Database 'DB_HFV_ST4' running the upgrade step from version 893 to version 894.
Database 'DB_HFV_ST4' running the upgrade step from version 894 to version 895.
Database 'DB_HFV_ST4' running the upgrade step from version 895 to version 896.
Database 'DB_HFV_ST4' running the upgrade step from version 896 to version 897.
Database 'DB_HFV_ST4' running the upgrade step from version 897 to version 898.
Database 'DB_HFV_ST4' running the upgrade step from version 898 to version 899.
Database 'DB_HFV_ST4' running the upgrade step from version 899 to version 900.
Database 'DB_HFV_ST4' running the upgrade step from version 900 to version 901.
Database 'DB_HFV_ST4' running the upgrade step from version 901 to version 902.
Database 'DB_HFV_ST4' running the upgrade step from version 902 to version 903.
Database 'DB_HFV_ST4' running the upgrade step from version 903 to version 904.
Database 'DB_HFV_ST4' running the upgrade step from version 904 to version 905.
Database 'DB_HFV_ST4' running the upgrade step from version 905 to version 906.
Database 'DB_HFV_ST4' running the upgrade step from version 906 to version 907.
Database 'DB_HFV_ST4' running the upgrade step from version 907 to version 908.
Database 'DB_HFV_ST4' running the upgrade step from version 908 to version 909.
Database 'DB_HFV_ST4' running the upgrade step from version 909 to version 910.
Database 'DB_HFV_ST4' running the upgrade step from version 910 to version 911.
Database 'DB_HFV_ST4' running the upgrade step from version 911 to version 912.
Database 'DB_HFV_ST4' running the upgrade step from version 912 to version 913.
Database 'DB_HFV_ST4' running the upgrade step from version 913 to version 914.
Database 'DB_HFV_ST4' running the upgrade step from version 914 to version 915.
Database 'DB_HFV_ST4' running the upgrade step from version 915 to version 916.
Database 'DB_HFV_ST4' running the upgrade step from version 916 to version 917.
Database 'DB_HFV_ST4' running the upgrade step from version 917 to version 918.
Database 'DB_HFV_ST4' running the upgrade step from version 918 to version 919.
Database 'DB_HFV_ST4' running the upgrade step from version 919 to version 920.
Database 'DB_HFV_ST4' running the upgrade step from version 920 to version 921.
Database 'DB_HFV_ST4' running the upgrade step from version 921 to version 922.
Database 'DB_HFV_ST4' running the upgrade step from version 922 to version 923.
Database 'DB_HFV_ST4' running the upgrade step from version 923 to version 924.
Database 'DB_HFV_ST4' running the upgrade step from version 924 to version 925.
Database 'DB_HFV_ST4' running the upgrade step from version 925 to version 926.
Database 'DB_HFV_ST4' running the upgrade step from version 926 to version 927.
Database 'DB_HFV_ST4' running the upgrade step from version 927 to version 928.
Database 'DB_HFV_ST4' running the upgrade step from version 928 to version 929.
Database 'DB_HFV_ST4' running the upgrade step from version 929 to version 930.
Database 'DB_HFV_ST4' running the upgrade step from version 930 to version 931.
Database 'DB_HFV_ST4' running the upgrade step from version 931 to version 932.
Database 'DB_HFV_ST4' running the upgrade step from version 932 to version 933.
Database 'DB_HFV_ST4' running the upgrade step from version 933 to version 934.
Database 'DB_HFV_ST4' running the upgrade step from version 934 to version 935.
Database 'DB_HFV_ST4' running the upgrade step from version 935 to version 936.
Database 'DB_HFV_ST4' running the upgrade step from version 936 to version 937.
Database 'DB_HFV_ST4' running the upgrade step from version 937 to version 938.
Database 'DB_HFV_ST4' running the upgrade step from version 938 to version 939.
Database 'DB_HFV_ST4' running the upgrade step from version 939 to version 940.
Database 'DB_HFV_ST4' running the upgrade step from version 940 to version 941.
Database 'DB_HFV_ST4' running the upgrade step from version 941 to version 942.
Database 'DB_HFV_ST4' running the upgrade step from version 942 to version 943.
Database 'DB_HFV_ST4' running the upgrade step from version 943 to version 944.
Database 'DB_HFV_ST4' running the upgrade step from version 944 to version 945.
Database 'DB_HFV_ST4' running the upgrade step from version 945 to version 946.
Database 'DB_HFV_ST4' running the upgrade step from version 946 to version 947.
Database 'DB_HFV_ST4' running the upgrade step from version 947 to version 948.
Database 'DB_HFV_ST4' running the upgrade step from version 948 to version 949.
Database 'DB_HFV_ST4' running the upgrade step from version 949 to version 950.
Database 'DB_HFV_ST4' running the upgrade step from version 950 to version 951.
Database 'DB_HFV_ST4' running the upgrade step from version 951 to version 952.
Database 'DB_HFV_ST4' running the upgrade step from version 952 to version 953.
Database 'DB_HFV_ST4' running the upgrade step from version 953 to version 954.
Database 'DB_HFV_ST4' running the upgrade step from version 954 to version 955.
Database 'DB_HFV_ST4' running the upgrade step from version 955 to version 956.
Database 'DB_HFV_ST4' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 5623 pages in 1.487 seconds (29.540 MB/sec).
* run end
 
* restore: server[CNACLTWCPD403S]>>[CNSISTWSQL100], database[DB_IWS_GNL]>>[DB_IWS_GNL_ST4]

(2 rows affected)
* run sql:
restore database DB_IWS_GNL_ST4
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\CNACLTWCPD403S_DB_IWS_GNL_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'DB_IWS_GNL_Data' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_IWS_GNL_ST4.mdf',
     move 'DB_IWS_GNL_Log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_IWS_GNL_ST4_log.ldf',
     file = 1,
     --medianame = 'CNACLTWCPD403S_DB_IWS_GNL_full_backup_2025_04_09_16_02_28',
     stats = 20;
20 percent processed.
40 percent processed.
60 percent processed.
80 percent processed.
100 percent processed.
Processed 21256 pages for database 'DB_IWS_GNL_ST4', file 'DB_IWS_GNL_Data' on file 1.
Processed 2 pages for database 'DB_IWS_GNL_ST4', file 'DB_IWS_GNL_Log' on file 1.
Converting database 'DB_IWS_GNL_ST4' from version 852 to the current version 957.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 852 to version 853.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 853 to version 854.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 854 to version 855.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 855 to version 856.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 856 to version 857.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 857 to version 858.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 858 to version 859.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 859 to version 860.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 860 to version 861.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 861 to version 862.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 862 to version 863.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 863 to version 864.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 864 to version 865.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 865 to version 866.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 866 to version 867.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 867 to version 868.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 868 to version 869.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 869 to version 875.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 875 to version 876.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 876 to version 877.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 877 to version 878.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 878 to version 879.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 879 to version 880.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 880 to version 881.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 881 to version 882.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 882 to version 883.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 883 to version 884.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 884 to version 885.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 885 to version 886.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 886 to version 887.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 887 to version 888.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 888 to version 889.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 889 to version 890.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 890 to version 891.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 891 to version 892.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 892 to version 893.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 893 to version 894.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 894 to version 895.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 895 to version 896.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 896 to version 897.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 897 to version 898.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 898 to version 899.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 899 to version 900.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 900 to version 901.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 901 to version 902.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 902 to version 903.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 903 to version 904.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 904 to version 905.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 905 to version 906.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 906 to version 907.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 907 to version 908.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 908 to version 909.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 909 to version 910.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 910 to version 911.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 911 to version 912.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 912 to version 913.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 913 to version 914.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 914 to version 915.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 915 to version 916.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 916 to version 917.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 917 to version 918.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 918 to version 919.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 919 to version 920.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 920 to version 921.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 921 to version 922.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 922 to version 923.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 923 to version 924.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 924 to version 925.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 925 to version 926.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 926 to version 927.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 927 to version 928.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 928 to version 929.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 929 to version 930.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 930 to version 931.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 931 to version 932.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 932 to version 933.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 933 to version 934.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 934 to version 935.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 935 to version 936.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 936 to version 937.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 937 to version 938.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 938 to version 939.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 939 to version 940.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 940 to version 941.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 941 to version 942.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 942 to version 943.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 943 to version 944.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 944 to version 945.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 945 to version 946.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 946 to version 947.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 947 to version 948.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 948 to version 949.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 949 to version 950.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 950 to version 951.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 951 to version 952.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 952 to version 953.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 953 to version 954.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 954 to version 955.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 955 to version 956.
Database 'DB_IWS_GNL_ST4' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 21258 pages in 1.610 seconds (103.150 MB/sec).
* run end
 
* restore: server[CNACLTWCPD403S]>>[CNSISTWSQL100], database[DB_IWS_SCAN]>>[DB_IWS_SCAN_ST4]

(2 rows affected)
* run sql:
restore database DB_IWS_SCAN_ST4
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\CNACLTWCPD403S_DB_IWS_SCAN_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'DB_IWS_SCAN' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_IWS_SCAN_ST4.mdf',
     move 'DB_IWS_SCAN_log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_IWS_SCAN_ST4_log.ldf',
     file = 1,
     --medianame = 'CNACLTWCPD403S_DB_IWS_SCAN_full_backup_2025_04_09_16_02_28',
     stats = 20;
20 percent processed.
40 percent processed.
60 percent processed.
80 percent processed.
100 percent processed.
Processed 126728 pages for database 'DB_IWS_SCAN_ST4', file 'DB_IWS_SCAN' on file 1.
Processed 1 pages for database 'DB_IWS_SCAN_ST4', file 'DB_IWS_SCAN_log' on file 1.
Converting database 'DB_IWS_SCAN_ST4' from version 852 to the current version 957.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 852 to version 853.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 853 to version 854.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 854 to version 855.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 855 to version 856.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 856 to version 857.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 857 to version 858.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 858 to version 859.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 859 to version 860.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 860 to version 861.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 861 to version 862.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 862 to version 863.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 863 to version 864.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 864 to version 865.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 865 to version 866.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 866 to version 867.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 867 to version 868.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 868 to version 869.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 869 to version 875.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 875 to version 876.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 876 to version 877.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 877 to version 878.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 878 to version 879.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 879 to version 880.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 880 to version 881.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 881 to version 882.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 882 to version 883.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 883 to version 884.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 884 to version 885.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 885 to version 886.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 886 to version 887.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 887 to version 888.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 888 to version 889.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 889 to version 890.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 890 to version 891.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 891 to version 892.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 892 to version 893.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 893 to version 894.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 894 to version 895.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 895 to version 896.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 896 to version 897.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 897 to version 898.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 898 to version 899.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 899 to version 900.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 900 to version 901.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 901 to version 902.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 902 to version 903.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 903 to version 904.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 904 to version 905.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 905 to version 906.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 906 to version 907.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 907 to version 908.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 908 to version 909.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 909 to version 910.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 910 to version 911.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 911 to version 912.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 912 to version 913.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 913 to version 914.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 914 to version 915.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 915 to version 916.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 916 to version 917.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 917 to version 918.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 918 to version 919.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 919 to version 920.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 920 to version 921.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 921 to version 922.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 922 to version 923.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 923 to version 924.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 924 to version 925.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 925 to version 926.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 926 to version 927.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 927 to version 928.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 928 to version 929.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 929 to version 930.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 930 to version 931.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 931 to version 932.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 932 to version 933.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 933 to version 934.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 934 to version 935.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 935 to version 936.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 936 to version 937.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 937 to version 938.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 938 to version 939.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 939 to version 940.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 940 to version 941.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 941 to version 942.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 942 to version 943.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 943 to version 944.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 944 to version 945.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 945 to version 946.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 946 to version 947.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 947 to version 948.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 948 to version 949.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 949 to version 950.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 950 to version 951.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 951 to version 952.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 952 to version 953.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 953 to version 954.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 954 to version 955.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 955 to version 956.
Database 'DB_IWS_SCAN_ST4' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 126729 pages in 11.768 seconds (84.132 MB/sec).
* run end
 
* restore: server[CNACLTWCPD403S]>>[CNSISTWSQL100], database[DB_SIGN]>>[DB_SIGN_ST4]

(2 rows affected)
* run sql:
restore database DB_SIGN_ST4
from disk = '\\cnsistwscl020\Newsis Backup\FullBackup\CNACLTWCPD403S_DB_SIGN_full_backup_2025_04_09_16_02_28.bak'
with recovery,
     move 'DB_SIGN_Data' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_SIGN_ST4.mdf',
     move 'DB_SIGN_Log' to 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\DB_SIGN_ST4_log.ldf',
     file = 1,
     --medianame = 'CNACLTWCPD403S_DB_SIGN_full_backup_2025_04_09_16_02_28',
     stats = 20;
20 percent processed.
40 percent processed.
60 percent processed.
80 percent processed.
100 percent processed.
Processed 19104 pages for database 'DB_SIGN_ST4', file 'DB_SIGN_Data' on file 1.
Processed 2 pages for database 'DB_SIGN_ST4', file 'DB_SIGN_Log' on file 1.
Converting database 'DB_SIGN_ST4' from version 852 to the current version 957.
Database 'DB_SIGN_ST4' running the upgrade step from version 852 to version 853.
Database 'DB_SIGN_ST4' running the upgrade step from version 853 to version 854.
Database 'DB_SIGN_ST4' running the upgrade step from version 854 to version 855.
Database 'DB_SIGN_ST4' running the upgrade step from version 855 to version 856.
Database 'DB_SIGN_ST4' running the upgrade step from version 856 to version 857.
Database 'DB_SIGN_ST4' running the upgrade step from version 857 to version 858.
Database 'DB_SIGN_ST4' running the upgrade step from version 858 to version 859.
Database 'DB_SIGN_ST4' running the upgrade step from version 859 to version 860.
Database 'DB_SIGN_ST4' running the upgrade step from version 860 to version 861.
Database 'DB_SIGN_ST4' running the upgrade step from version 861 to version 862.
Database 'DB_SIGN_ST4' running the upgrade step from version 862 to version 863.
Database 'DB_SIGN_ST4' running the upgrade step from version 863 to version 864.
Database 'DB_SIGN_ST4' running the upgrade step from version 864 to version 865.
Database 'DB_SIGN_ST4' running the upgrade step from version 865 to version 866.
Database 'DB_SIGN_ST4' running the upgrade step from version 866 to version 867.
Database 'DB_SIGN_ST4' running the upgrade step from version 867 to version 868.
Database 'DB_SIGN_ST4' running the upgrade step from version 868 to version 869.
Database 'DB_SIGN_ST4' running the upgrade step from version 869 to version 875.
Database 'DB_SIGN_ST4' running the upgrade step from version 875 to version 876.
Database 'DB_SIGN_ST4' running the upgrade step from version 876 to version 877.
Database 'DB_SIGN_ST4' running the upgrade step from version 877 to version 878.
Database 'DB_SIGN_ST4' running the upgrade step from version 878 to version 879.
Database 'DB_SIGN_ST4' running the upgrade step from version 879 to version 880.
Database 'DB_SIGN_ST4' running the upgrade step from version 880 to version 881.
Database 'DB_SIGN_ST4' running the upgrade step from version 881 to version 882.
Database 'DB_SIGN_ST4' running the upgrade step from version 882 to version 883.
Database 'DB_SIGN_ST4' running the upgrade step from version 883 to version 884.
Database 'DB_SIGN_ST4' running the upgrade step from version 884 to version 885.
Database 'DB_SIGN_ST4' running the upgrade step from version 885 to version 886.
Database 'DB_SIGN_ST4' running the upgrade step from version 886 to version 887.
Database 'DB_SIGN_ST4' running the upgrade step from version 887 to version 888.
Database 'DB_SIGN_ST4' running the upgrade step from version 888 to version 889.
Database 'DB_SIGN_ST4' running the upgrade step from version 889 to version 890.
Database 'DB_SIGN_ST4' running the upgrade step from version 890 to version 891.
Database 'DB_SIGN_ST4' running the upgrade step from version 891 to version 892.
Database 'DB_SIGN_ST4' running the upgrade step from version 892 to version 893.
Database 'DB_SIGN_ST4' running the upgrade step from version 893 to version 894.
Database 'DB_SIGN_ST4' running the upgrade step from version 894 to version 895.
Database 'DB_SIGN_ST4' running the upgrade step from version 895 to version 896.
Database 'DB_SIGN_ST4' running the upgrade step from version 896 to version 897.
Database 'DB_SIGN_ST4' running the upgrade step from version 897 to version 898.
Database 'DB_SIGN_ST4' running the upgrade step from version 898 to version 899.
Database 'DB_SIGN_ST4' running the upgrade step from version 899 to version 900.
Database 'DB_SIGN_ST4' running the upgrade step from version 900 to version 901.
Database 'DB_SIGN_ST4' running the upgrade step from version 901 to version 902.
Database 'DB_SIGN_ST4' running the upgrade step from version 902 to version 903.
Database 'DB_SIGN_ST4' running the upgrade step from version 903 to version 904.
Database 'DB_SIGN_ST4' running the upgrade step from version 904 to version 905.
Database 'DB_SIGN_ST4' running the upgrade step from version 905 to version 906.
Database 'DB_SIGN_ST4' running the upgrade step from version 906 to version 907.
Database 'DB_SIGN_ST4' running the upgrade step from version 907 to version 908.
Database 'DB_SIGN_ST4' running the upgrade step from version 908 to version 909.
Database 'DB_SIGN_ST4' running the upgrade step from version 909 to version 910.
Database 'DB_SIGN_ST4' running the upgrade step from version 910 to version 911.
Database 'DB_SIGN_ST4' running the upgrade step from version 911 to version 912.
Database 'DB_SIGN_ST4' running the upgrade step from version 912 to version 913.
Database 'DB_SIGN_ST4' running the upgrade step from version 913 to version 914.
Database 'DB_SIGN_ST4' running the upgrade step from version 914 to version 915.
Database 'DB_SIGN_ST4' running the upgrade step from version 915 to version 916.
Database 'DB_SIGN_ST4' running the upgrade step from version 916 to version 917.
Database 'DB_SIGN_ST4' running the upgrade step from version 917 to version 918.
Database 'DB_SIGN_ST4' running the upgrade step from version 918 to version 919.
Database 'DB_SIGN_ST4' running the upgrade step from version 919 to version 920.
Database 'DB_SIGN_ST4' running the upgrade step from version 920 to version 921.
Database 'DB_SIGN_ST4' running the upgrade step from version 921 to version 922.
Database 'DB_SIGN_ST4' running the upgrade step from version 922 to version 923.
Database 'DB_SIGN_ST4' running the upgrade step from version 923 to version 924.
Database 'DB_SIGN_ST4' running the upgrade step from version 924 to version 925.
Database 'DB_SIGN_ST4' running the upgrade step from version 925 to version 926.
Database 'DB_SIGN_ST4' running the upgrade step from version 926 to version 927.
Database 'DB_SIGN_ST4' running the upgrade step from version 927 to version 928.
Database 'DB_SIGN_ST4' running the upgrade step from version 928 to version 929.
Database 'DB_SIGN_ST4' running the upgrade step from version 929 to version 930.
Database 'DB_SIGN_ST4' running the upgrade step from version 930 to version 931.
Database 'DB_SIGN_ST4' running the upgrade step from version 931 to version 932.
Database 'DB_SIGN_ST4' running the upgrade step from version 932 to version 933.
Database 'DB_SIGN_ST4' running the upgrade step from version 933 to version 934.
Database 'DB_SIGN_ST4' running the upgrade step from version 934 to version 935.
Database 'DB_SIGN_ST4' running the upgrade step from version 935 to version 936.
Database 'DB_SIGN_ST4' running the upgrade step from version 936 to version 937.
Database 'DB_SIGN_ST4' running the upgrade step from version 937 to version 938.
Database 'DB_SIGN_ST4' running the upgrade step from version 938 to version 939.
Database 'DB_SIGN_ST4' running the upgrade step from version 939 to version 940.
Database 'DB_SIGN_ST4' running the upgrade step from version 940 to version 941.
Database 'DB_SIGN_ST4' running the upgrade step from version 941 to version 942.
Database 'DB_SIGN_ST4' running the upgrade step from version 942 to version 943.
Database 'DB_SIGN_ST4' running the upgrade step from version 943 to version 944.
Database 'DB_SIGN_ST4' running the upgrade step from version 944 to version 945.
Database 'DB_SIGN_ST4' running the upgrade step from version 945 to version 946.
Database 'DB_SIGN_ST4' running the upgrade step from version 946 to version 947.
Database 'DB_SIGN_ST4' running the upgrade step from version 947 to version 948.
Database 'DB_SIGN_ST4' running the upgrade step from version 948 to version 949.
Database 'DB_SIGN_ST4' running the upgrade step from version 949 to version 950.
Database 'DB_SIGN_ST4' running the upgrade step from version 950 to version 951.
Database 'DB_SIGN_ST4' running the upgrade step from version 951 to version 952.
Database 'DB_SIGN_ST4' running the upgrade step from version 952 to version 953.
Database 'DB_SIGN_ST4' running the upgrade step from version 953 to version 954.
Database 'DB_SIGN_ST4' running the upgrade step from version 954 to version 955.
Database 'DB_SIGN_ST4' running the upgrade step from version 955 to version 956.
Database 'DB_SIGN_ST4' running the upgrade step from version 956 to version 957.
RESTORE DATABASE successfully processed 19106 pages in 1.331 seconds (112.145 MB/sec).
* run end
 

(10 rows affected)

Completion time: 2025-04-09T17:15:39.5018066+08:00


*/





