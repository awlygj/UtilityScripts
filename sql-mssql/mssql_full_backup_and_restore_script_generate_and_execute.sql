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

create table #DB_Migration_LIST (
    oserver nvarchar(255) not null,
    nserver nvarchar(255) not null,
    odb     nvarchar(255) not null,
    ndb     nvarchar(255) not null,
    primary key (nserver, ndb)
);

insert into #DB_Migration_LIST values
('oserver', 'nserver', 'odb', 'ndb');

declare @run_mode  varchar(255) = 'backup';    --backup; restore
declare @view_only int = 1;

declare @bak_path nvarchar(max) = '\\fileserver\Newsis Backup\FullBackup\';
declare @bak_type nvarchar(max) = '_full_backup';
declare @bak_dt   nvarchar(max) = '_2025_04_09_16_02_28';    --select format(getdate(), '_yyyy_MM_dd_HH_mm_ss');
declare @bak_ext  nvarchar(max) = '.bak';
declare @bak_desc nvarchar(max) = 'DB Migration';

declare @data_path nvarchar(max) = 'D:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\';

declare @exec_sql nvarchar(max);

declare @oserver nvarchar(max);
declare @nserver nvarchar(max);
declare @odb     nvarchar(max);
declare @ndb     nvarchar(max);

declare @prev_oserver nvarchar(max);
declare @prev_odb     nvarchar(max);

declare DB_Migration_LIST cursor for
    select *
    from #DB_Migration_LIST
    order by oserver, odb, nserver, ndb;

open DB_Migration_LIST;

fetch next from DB_Migration_LIST
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

    fetch next from DB_Migration_LIST
    into @oserver, @nserver, @odb, @ndb;
end

close DB_Migration_LIST;
deallocate DB_Migration_LIST;

select t.*, d.name, d.state_desc, d.user_access_desc, d.recovery_model_desc, d.is_encrypted, d.is_master_key_encrypted_by_server
from #DB_Migration_LIST as t
left outer join sys.databases as d
    on iif(@run_mode = 'backup', t.odb, t.ndb) = d.name
where iif(@run_mode = 'backup', t.oserver, t.nserver) = @@servername;

drop table #restore_filelistonly;
drop table #DB_Migration_LIST;
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

GO
